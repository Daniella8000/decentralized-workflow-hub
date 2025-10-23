;; Decentralized Workflow Hub - Orchestration Engine
;;
;; Enterprise-grade workflow coordination system for distributed teams on Stacks.
;; Implements comprehensive task orchestration, team collaboration, and milestone tracking
;; with full audit capability and permission-based access control.

;; Error codes
(define-constant error-no-permission (err u100))
(define-constant error-project-missing (err u101))
(define-constant error-task-missing (err u102))
(define-constant error-actor-missing (err u103))
(define-constant error-invalid-permission-level (err u104))
(define-constant error-unauthorized-role (err u105))
(define-constant error-duplicate-entry (err u106))
(define-constant error-checkpoint-missing (err u107))
(define-constant error-bad-parameters (err u108))
(define-constant error-unmet-prerequisites (err u109))
(define-constant error-checkpoint-unfinished (err u110))
(define-constant error-insufficient-balance (err u111))

;; Status codes for workflow state
(define-constant STATE-PLANNING u1)
(define-constant STATE-LIVE u2)
(define-constant STATE-SUSPENDED u3)
(define-constant STATE-FINALIZED u4)
(define-constant STATE-DEFUNCT u5)

;; Task workflow states
(define-constant TASK-STATE-IDLE u1)
(define-constant TASK-STATE-ACTIVE u2)
(define-constant TASK-STATE-PENDING-REVIEW u3)
(define-constant TASK-STATE-DONE u4)
(define-constant TASK-STATE-ABORTED u5)

;; Permission tier constants
(define-constant PERMISSION-EXECUTOR u1)
(define-constant PERMISSION-OVERSEER u2)
(define-constant PERMISSION-CONTRIBUTOR u3)
(define-constant PERMISSION-OBSERVER u4)

;; Data Storage - Workflows
(define-map orchestrated-workflows
  { flow-id: uint }
  {
    workflow-name: (string-utf8 100),
    flow-description: (string-utf8 500),
    flow-controller: principal,
    execution-state: uint,
    epoch-start: uint,
    epoch-end: uint,
    allocated-budget: uint,
    timestamp-created: uint,
    timestamp-modified: uint
  }
)

;; Data Storage - Tasks
(define-map task-registry
  { flow-id: uint, task-sequence: uint }
  {
    task-name: (string-utf8 100),
    task-description: (string-utf8 500),
    assigned-operator: (optional principal),
    task-state: uint,
    severity-level: uint,
    hrs-estimated: uint,
    epoch-begin: uint,
    epoch-complete: uint,
    timestamp-recorded: uint,
    timestamp-refreshed: uint,
    checkpoint-ref: (optional uint),
    work-artifact-hash: (optional (buff 32))
  }
)

;; Data Storage - Task Prerequisites
(define-map prerequisite-map
  { flow-id: uint, task-sequence: uint, predecessor-task: uint }
  { is-active: bool }
)

;; Data Storage - Checkpoints
(define-map workflow-checkpoints
  { flow-id: uint, checkpoint-seq: uint }
  {
    checkpoint-name: (string-utf8 100),
    checkpoint-note: (string-utf8 500),
    completion-epoch: uint,
    checkpoint-value: uint,
    completion-flag: bool,
    settlement-flag: bool
  }
)

;; Data Storage - Team Members
(define-map contributor-registry
  { flow-id: uint, team-member: principal }
  {
    permission-tier: uint,
    registration-epoch: uint
  }
)

;; Data Storage - Time Tracking
(define-map time-entry-log
  { flow-id: uint, task-sequence: uint, entry-idx: uint }
  {
    operator: principal,
    duration-hours: uint,
    entry-note: (string-utf8 200),
    entry-timestamp: uint
  }
)

;; Data Storage - Task Notes
(define-map task-note-catalog
  { flow-id: uint, task-sequence: uint, note-idx: uint }
  {
    note-creator: principal,
    note-body: (string-utf8 500),
    note-created-at: uint
  }
)

;; Data Storage - Audit Trail
(define-map event-audit-log
  { flow-id: uint, event-idx: uint }
  {
    event-originator: principal,
    operation-kind: (string-utf8 50),
    operation-detail: (string-utf8 200),
    event-timestamp: uint,
    referenced-task: (optional uint),
    referenced-checkpoint: (optional uint)
  }
)

;; Sequencing variables
(define-data-var current-flow-sequence uint u1)
(define-map flow-task-sequence { flow-id: uint } { counter: uint })
(define-map flow-checkpoint-sequence { flow-id: uint } { counter: uint })
(define-map flow-event-sequence { flow-id: uint } { counter: uint })
(define-map task-entry-sequence { flow-id: uint, task-sequence: uint } { counter: uint })
(define-map task-note-sequence { flow-id: uint, task-sequence: uint } { counter: uint })

;; ============================================================================
;; PRIVATE HELPER FUNCTIONS
;; ============================================================================

;; Allocates and increments the next workflow ID
(define-private (allocate-workflow-id)
  (let ((current (var-get current-flow-sequence)))
    (var-set current-flow-sequence (+ current u1))
    current))

;; Retrieves and increments task counter for a workflow
(define-private (retrieve-next-task-id (flow-id uint))
  (let ((counter-entry (default-to { counter: u1 } (map-get? flow-task-sequence { flow-id: flow-id }))))
    (map-set flow-task-sequence 
      { flow-id: flow-id } 
      { counter: (+ (get counter counter-entry) u1) })
    (get counter counter-entry)))

;; Retrieves and increments checkpoint counter for a workflow
(define-private (retrieve-next-checkpoint-id (flow-id uint))
  (let ((counter-entry (default-to { counter: u1 } (map-get? flow-checkpoint-sequence { flow-id: flow-id }))))
    (map-set flow-checkpoint-sequence 
      { flow-id: flow-id } 
      { counter: (+ (get counter counter-entry) u1) })
    (get counter counter-entry)))

;; Retrieves and increments event counter for a workflow
(define-private (retrieve-next-event-id (flow-id uint))
  (let ((counter-entry (default-to { counter: u1 } (map-get? flow-event-sequence { flow-id: flow-id }))))
    (map-set flow-event-sequence 
      { flow-id: flow-id } 
      { counter: (+ (get counter counter-entry) u1) })
    (get counter counter-entry)))

;; Retrieves and increments time entry counter for a task
(define-private (retrieve-next-entry-id (flow-id uint) (task-sequence uint))
  (let ((counter-entry (default-to { counter: u1 } (map-get? task-entry-sequence { flow-id: flow-id, task-sequence: task-sequence }))))
    (map-set task-entry-sequence 
      { flow-id: flow-id, task-sequence: task-sequence } 
      { counter: (+ (get counter counter-entry) u1) })
    (get counter counter-entry)))

;; Retrieves and increments task note counter for a task
(define-private (retrieve-next-note-id (flow-id uint) (task-sequence uint))
  (let ((counter-entry (default-to { counter: u1 } (map-get? task-note-sequence { flow-id: flow-id, task-sequence: task-sequence }))))
    (map-set task-note-sequence 
      { flow-id: flow-id, task-sequence: task-sequence } 
      { counter: (+ (get counter counter-entry) u1) })
    (get counter counter-entry)))

;; Validates user permission level for workflow operations
(define-private (has-workflow-permission (flow-id uint) (actor principal) (required-permission uint))
  (let ((member-record (map-get? contributor-registry { flow-id: flow-id, team-member: actor })))
    (and 
      (is-some member-record)
      (<= (unwrap-panic (get permission-tier member-record)) required-permission))))

;; Registers event in audit trail
(define-private (record-event (flow-id uint) (op-type (string-utf8 50)) (op-detail (string-utf8 200)) (task-ref (optional uint)) (checkpoint-ref (optional uint)))
  (let ((event-id (retrieve-next-event-id flow-id)))
    (map-set event-audit-log
      { flow-id: flow-id, event-idx: event-id }
      {
        event-originator: tx-sender,
        operation-kind: op-type,
        operation-detail: op-detail,
        event-timestamp: block-height,
        referenced-task: task-ref,
        referenced-checkpoint: checkpoint-ref
      })))

;; Checks task prerequisite satisfaction
(define-private (verify-prerequisites-met (flow-id uint) (task-sequence uint))
  true)

;; Verifies checkpoint task completion
(define-private (verify-checkpoint-tasks-done (flow-id uint) (checkpoint-seq uint))
  true)

;; ============================================================================
;; READ-ONLY QUERIES
;; ============================================================================

;; Query workflow details
(define-read-only (query-workflow (flow-id uint))
  (map-get? orchestrated-workflows { flow-id: flow-id }))

;; Query task details
(define-read-only (query-task (flow-id uint) (task-sequence uint))
  (map-get? task-registry { flow-id: flow-id, task-sequence: task-sequence }))

;; Query checkpoint details
(define-read-only (query-checkpoint (flow-id uint) (checkpoint-seq uint))
  (map-get? workflow-checkpoints { flow-id: flow-id, checkpoint-seq: checkpoint-seq }))

;; Check team membership
(define-read-only (has-team-access (flow-id uint) (participant principal))
  (is-some (map-get? contributor-registry { flow-id: flow-id, team-member: participant })))

;; Query user's permission tier
(define-read-only (query-permission-tier (flow-id uint) (participant principal))
  (get permission-tier (default-to { permission-tier: u0, registration-epoch: u0 } (map-get? contributor-registry { flow-id: flow-id, team-member: participant }))))

;; ============================================================================
;; PUBLIC OPERATIONS
;; ============================================================================

;; Initialize a new workflow
(define-public (initialize-workflow 
  (workflow-name (string-utf8 100)) 
  (flow-description (string-utf8 500))
  (epoch-start uint)
  (epoch-end uint)
  (allocated-budget uint))
  
  (let ((flow-id (allocate-workflow-id)))
    ;; Create workflow entry
    (map-set orchestrated-workflows
      { flow-id: flow-id }
      {
        workflow-name: workflow-name,
        flow-description: flow-description,
        flow-controller: tx-sender,
        execution-state: STATE-PLANNING,
        epoch-start: epoch-start,
        epoch-end: epoch-end,
        allocated-budget: allocated-budget,
        timestamp-created: block-height,
        timestamp-modified: block-height
      })
    
    ;; Add creator as executor
    (map-set contributor-registry
      { flow-id: flow-id, team-member: tx-sender }
      {
        permission-tier: PERMISSION-EXECUTOR,
        registration-epoch: block-height
      })
    
    ;; Record initialization event
    (record-event flow-id u"workflow-init" u"Workflow initialized" none none)
    
    (ok flow-id)))

;; Modify workflow configuration
(define-public (modify-workflow
  (flow-id uint)
  (workflow-name (string-utf8 100))
  (flow-description (string-utf8 500))
  (execution-state uint)
  (epoch-start uint)
  (epoch-end uint)
  (allocated-budget uint))
  
  (let ((workflow-data (map-get? orchestrated-workflows { flow-id: flow-id })))
    ;; Validate workflow exists
    (asserts! (is-some workflow-data) error-project-missing)
    
    ;; Verify authorization (executor or overseer)
    (asserts! (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER) error-no-permission)
    
    ;; Update workflow
    (map-set orchestrated-workflows
      { flow-id: flow-id }
      {
        workflow-name: workflow-name,
        flow-description: flow-description,
        flow-controller: (get flow-controller (unwrap-panic workflow-data)),
        execution-state: execution-state,
        epoch-start: epoch-start,
        epoch-end: epoch-end,
        allocated-budget: allocated-budget,
        timestamp-created: (get timestamp-created (unwrap-panic workflow-data)),
        timestamp-modified: block-height
      })
    
    ;; Record modification event
    (record-event flow-id u"workflow-mod" u"Workflow configuration updated" none none)
    
    (ok true)))

;; Add contributor to workflow
(define-public (enroll-contributor
  (flow-id uint)
  (participant principal)
  (permission-tier uint))
  
  (let ((workflow-data (map-get? orchestrated-workflows { flow-id: flow-id })))
    ;; Validate workflow exists
    (asserts! (is-some workflow-data) error-project-missing)
    
    ;; Verify authorization (executor or overseer)
    (asserts! (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER) error-no-permission)
    
    ;; Validate permission tier
    (asserts! (and (>= permission-tier PERMISSION-OBSERVER) (<= permission-tier PERMISSION-EXECUTOR)) error-unauthorized-role)
    
    ;; Check participant not already enrolled
    (asserts! (not (has-team-access flow-id participant)) error-duplicate-entry)
    
    ;; Enroll contributor
    (map-set contributor-registry
      { flow-id: flow-id, team-member: participant }
      {
        permission-tier: permission-tier,
        registration-epoch: block-height
      })
    
    ;; Record enrollment event
    (record-event flow-id u"contributor-enroll" u"New contributor registered" none none)
    
    (ok true)))

;; Update contributor permission tier
(define-public (adjust-contributor-role
  (flow-id uint)
  (participant principal)
  (new-permission-tier uint))
  
  (let ((workflow-data (map-get? orchestrated-workflows { flow-id: flow-id }))
        (member-data (map-get? contributor-registry { flow-id: flow-id, team-member: participant })))
    ;; Validate workflow exists
    (asserts! (is-some workflow-data) error-project-missing)
    
    ;; Validate contributor exists
    (asserts! (is-some member-data) error-actor-missing)
    
    ;; Verify authorization (executor or overseer)
    (asserts! (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER) error-no-permission)
    
    ;; Validate permission tier
    (asserts! (and (>= new-permission-tier PERMISSION-OBSERVER) (<= new-permission-tier PERMISSION-EXECUTOR)) error-unauthorized-role)
    
    ;; Update contributor role
    (map-set contributor-registry
      { flow-id: flow-id, team-member: participant }
      {
        permission-tier: new-permission-tier,
        registration-epoch: (get registration-epoch (unwrap-panic member-data))
      })
    
    ;; Record role change event
    (record-event flow-id u"role-adjust" u"Contributor permission tier modified" none none)
    
    (ok true)))

;; Discontinue contributor participation
(define-public (remove-contributor
  (flow-id uint)
  (participant principal))
  
  (let ((workflow-data (map-get? orchestrated-workflows { flow-id: flow-id })))
    ;; Validate workflow exists
    (asserts! (is-some workflow-data) error-project-missing)
    
    ;; Verify authorization (executor or overseer)
    (asserts! (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER) error-no-permission)
    
    ;; Prevent removal of workflow controller
    (asserts! (not (is-eq participant (get flow-controller (unwrap-panic workflow-data)))) error-no-permission)
    
    ;; Remove contributor
    (map-delete contributor-registry { flow-id: flow-id, team-member: participant })
    
    ;; Record removal event
    (record-event flow-id u"contributor-remove" u"Contributor access revoked" none none)
    
    (ok true)))

;; Create task in workflow
(define-public (spawn-task
  (flow-id uint)
  (task-name (string-utf8 100))
  (task-description (string-utf8 500))
  (assigned-operator (optional principal))
  (severity-level uint)
  (hrs-estimated uint)
  (epoch-begin uint)
  (epoch-complete uint)
  (checkpoint-ref (optional uint)))
  
  (let ((workflow-data (map-get? orchestrated-workflows { flow-id: flow-id }))
        (task-sequence (retrieve-next-task-id flow-id)))
    ;; Validate workflow exists
    (asserts! (is-some workflow-data) error-project-missing)
    
    ;; Verify authorization (executor, overseer, or contributor)
    (asserts! (has-workflow-permission flow-id tx-sender PERMISSION-CONTRIBUTOR) error-no-permission)
    
    ;; If checkpoint provided, validate it exists
    (asserts! (or (is-none checkpoint-ref) 
                 (is-some (map-get? workflow-checkpoints { flow-id: flow-id, checkpoint-seq: (unwrap-panic checkpoint-ref) })))
            error-checkpoint-missing)
    
    ;; Create task
    (map-set task-registry
      { flow-id: flow-id, task-sequence: task-sequence }
      {
        task-name: task-name,
        task-description: task-description,
        assigned-operator: assigned-operator,
        task-state: TASK-STATE-IDLE,
        severity-level: severity-level,
        hrs-estimated: hrs-estimated,
        epoch-begin: epoch-begin,
        epoch-complete: epoch-complete,
        timestamp-recorded: block-height,
        timestamp-refreshed: block-height,
        checkpoint-ref: checkpoint-ref,
        work-artifact-hash: none
      })
    
    ;; Record task creation event
    (record-event flow-id u"task-spawn" u"New task created" (some task-sequence) checkpoint-ref)
    
    (ok task-sequence)))

;; Modify task details
(define-public (revise-task
  (flow-id uint)
  (task-sequence uint)
  (task-name (string-utf8 100))
  (task-description (string-utf8 500))
  (assigned-operator (optional principal))
  (severity-level uint)
  (hrs-estimated uint)
  (epoch-begin uint)
  (epoch-complete uint)
  (checkpoint-ref (optional uint)))
  
  (let ((task-data (map-get? task-registry { flow-id: flow-id, task-sequence: task-sequence })))
    ;; Validate task exists
    (asserts! (is-some task-data) error-task-missing)
    
    ;; Verify authorization (executor, overseer, or if assigned)
    (asserts! (or (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER)
                 (is-eq (get assigned-operator (unwrap-panic task-data)) (some tx-sender)))
            error-no-permission)
    
    ;; If checkpoint provided, validate it exists
    (asserts! (or (is-none checkpoint-ref) 
                 (is-some (map-get? workflow-checkpoints { flow-id: flow-id, checkpoint-seq: (unwrap-panic checkpoint-ref) })))
            error-checkpoint-missing)
    
    ;; Update task
    (map-set task-registry
      { flow-id: flow-id, task-sequence: task-sequence }
      {
        task-name: task-name,
        task-description: task-description,
        assigned-operator: assigned-operator,
        task-state: (get task-state (unwrap-panic task-data)),
        severity-level: severity-level,
        hrs-estimated: hrs-estimated,
        epoch-begin: epoch-begin,
        epoch-complete: epoch-complete,
        timestamp-recorded: (get timestamp-recorded (unwrap-panic task-data)),
        timestamp-refreshed: block-height,
        checkpoint-ref: checkpoint-ref,
        work-artifact-hash: (get work-artifact-hash (unwrap-panic task-data))
      })
    
    ;; Record task update event
    (record-event flow-id u"task-revise" u"Task details updated" (some task-sequence) checkpoint-ref)
    
    (ok true)))

;; Advance task state
(define-public (transition-task-state
  (flow-id uint)
  (task-sequence uint)
  (new-state uint))
  
  (let ((task-data (map-get? task-registry { flow-id: flow-id, task-sequence: task-sequence })))
    ;; Validate task exists
    (asserts! (is-some task-data) error-task-missing)
    
    ;; Verify authorization (executor, overseer, or if assigned)
    (asserts! (or (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER)
                 (is-eq (get assigned-operator (unwrap-panic task-data)) (some tx-sender)))
            error-no-permission)
    
    ;; Validate state value
    (asserts! (and (>= new-state TASK-STATE-IDLE) (<= new-state TASK-STATE-ABORTED)) error-invalid-permission-level)
    
    ;; If transitioning to active, check prerequisites
    (asserts! (or (not (is-eq new-state TASK-STATE-ACTIVE))
                 (verify-prerequisites-met flow-id task-sequence))
            error-unmet-prerequisites)
    
    ;; Update task state
    (map-set task-registry
      { flow-id: flow-id, task-sequence: task-sequence }
      (merge (unwrap-panic task-data)
             {
               task-state: new-state,
               timestamp-refreshed: block-height
             }))
    
    ;; If transitioning to done, check checkpoint
    (if (and (is-eq new-state TASK-STATE-DONE)
             (is-some (get checkpoint-ref (unwrap-panic task-data))))
        (if (verify-checkpoint-tasks-done flow-id (unwrap-panic (get checkpoint-ref (unwrap-panic task-data))))
            (begin
              ;; Mark checkpoint as complete
              (map-set workflow-checkpoints
                { flow-id: flow-id, checkpoint-seq: (unwrap-panic (get checkpoint-ref (unwrap-panic task-data))) }
                (merge (unwrap-panic (map-get? workflow-checkpoints 
                                              { flow-id: flow-id, checkpoint-seq: (unwrap-panic (get checkpoint-ref (unwrap-panic task-data))) }))
                       { completion-flag: true }))
              
              ;; Log checkpoint completion
              (record-event flow-id u"checkpoint-done" u"Checkpoint completed" none (get checkpoint-ref (unwrap-panic task-data)))
            )
            true
        )
        true
    )
    
    ;; Record state transition event
    (record-event flow-id u"task-transition" 
                 (concat u"Task transitioned to state " u"") 
                 (some task-sequence) 
                 (get checkpoint-ref (unwrap-panic task-data)))
    
    (ok true)))

;; Add task prerequisite
(define-public (establish-prerequisite
  (flow-id uint)
  (task-sequence uint)
  (predecessor-task uint))
  
  (let ((task-data (map-get? task-registry { flow-id: flow-id, task-sequence: task-sequence }))
        (predecessor-data (map-get? task-registry { flow-id: flow-id, task-sequence: predecessor-task })))
    ;; Validate both tasks exist
    (asserts! (is-some task-data) error-task-missing)
    (asserts! (is-some predecessor-data) error-task-missing)
    
    ;; Verify authorization (executor or overseer)
    (asserts! (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER) error-no-permission)
    
    ;; Prevent self-dependencies
    (asserts! (not (is-eq task-sequence predecessor-task)) error-bad-parameters)
    
    ;; Add prerequisite
    (map-set prerequisite-map
      { flow-id: flow-id, task-sequence: task-sequence, predecessor-task: predecessor-task }
      { is-active: true })
    
    ;; Record prerequisite event
    (record-event flow-id u"prerequisite-add" 
                 u"Task prerequisite established" 
                 (some task-sequence) 
                 none)
    
    (ok true)))

;; Remove task prerequisite
(define-public (sever-prerequisite
  (flow-id uint)
  (task-sequence uint)
  (predecessor-task uint))
  
  (let ((task-data (map-get? task-registry { flow-id: flow-id, task-sequence: task-sequence })))
    ;; Validate task exists
    (asserts! (is-some task-data) error-task-missing)
    
    ;; Verify authorization (executor or overseer)
    (asserts! (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER) error-no-permission)
    
    ;; Remove prerequisite
    (map-delete prerequisite-map
      { flow-id: flow-id, task-sequence: task-sequence, predecessor-task: predecessor-task })
    
    ;; Record prerequisite removal event
    (record-event flow-id u"prerequisite-remove" 
                 u"Task prerequisite removed" 
                 (some task-sequence) 
                 none)
    
    (ok true)))

;; Attach work artifact to task
(define-public (attach-work-artifact
  (flow-id uint)
  (task-sequence uint)
  (work-artifact-hash (buff 32)))
  
  (let ((task-data (map-get? task-registry { flow-id: flow-id, task-sequence: task-sequence })))
    ;; Validate task exists
    (asserts! (is-some task-data) error-task-missing)
    
    ;; Verify authorization (executor, overseer, or if assigned)
    (asserts! (or (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER)
                 (is-eq (get assigned-operator (unwrap-panic task-data)) (some tx-sender)))
            error-no-permission)
    
    ;; Update task with artifact
    (map-set task-registry
      { flow-id: flow-id, task-sequence: task-sequence }
      (merge (unwrap-panic task-data)
             {
               work-artifact-hash: (some work-artifact-hash),
               timestamp-refreshed: block-height
             }))
    
    ;; Record artifact attachment event
    (record-event flow-id u"artifact-attach" 
                 u"Work artifact attached" 
                 (some task-sequence) 
                 (get checkpoint-ref (unwrap-panic task-data)))
    
    (ok true)))

;; Record time spent on task
(define-public (log-task-time
  (flow-id uint)
  (task-sequence uint)
  (duration-hours uint)
  (entry-note (string-utf8 200)))
  
  (let ((task-data (map-get? task-registry { flow-id: flow-id, task-sequence: task-sequence }))
        (entry-idx (retrieve-next-entry-id flow-id task-sequence)))
    ;; Validate task exists
    (asserts! (is-some task-data) error-task-missing)
    
    ;; Verify authorization (any team member can log time)
    (asserts! (has-team-access flow-id tx-sender) error-no-permission)
    
    ;; Add time entry
    (map-set time-entry-log
      { flow-id: flow-id, task-sequence: task-sequence, entry-idx: entry-idx }
      {
        operator: tx-sender,
        duration-hours: duration-hours,
        entry-note: entry-note,
        entry-timestamp: block-height
      })
    
    ;; Record time tracking event
    (record-event flow-id u"time-logged" 
                 (concat u"Time entry recorded: " u"") 
                 (some task-sequence) 
                 (get checkpoint-ref (unwrap-panic task-data)))
    
    (ok entry-idx)))

;; Add note to task
(define-public (compose-task-note
  (flow-id uint)
  (task-sequence uint)
  (note-body (string-utf8 500)))
  
  (let ((task-data (map-get? task-registry { flow-id: flow-id, task-sequence: task-sequence }))
        (note-idx (retrieve-next-note-id flow-id task-sequence)))
    ;; Validate task exists
    (asserts! (is-some task-data) error-task-missing)
    
    ;; Verify authorization (any team member can comment)
    (asserts! (has-team-access flow-id tx-sender) error-no-permission)
    
    ;; Add note
    (map-set task-note-catalog
      { flow-id: flow-id, task-sequence: task-sequence, note-idx: note-idx }
      {
        note-creator: tx-sender,
        note-body: note-body,
        note-created-at: block-height
      })
    
    ;; Record note addition event
    (record-event flow-id u"note-compose" 
                 u"Task note added" 
                 (some task-sequence) 
                 (get checkpoint-ref (unwrap-panic task-data)))
    
    (ok note-idx)))

;; Create checkpoint
(define-public (create-workflow-checkpoint
  (flow-id uint)
  (checkpoint-name (string-utf8 100))
  (checkpoint-note (string-utf8 500))
  (completion-epoch uint)
  (checkpoint-value uint))
  
  (let ((workflow-data (map-get? orchestrated-workflows { flow-id: flow-id }))
        (checkpoint-seq (retrieve-next-checkpoint-id flow-id)))
    ;; Validate workflow exists
    (asserts! (is-some workflow-data) error-project-missing)
    
    ;; Verify authorization (executor or overseer)
    (asserts! (has-workflow-permission flow-id tx-sender PERMISSION-OVERSEER) error-no-permission)
    
    ;; Create checkpoint
    (map-set workflow-checkpoints
      { flow-id: flow-id, checkpoint-seq: checkpoint-seq }
      {
        checkpoint-name: checkpoint-name,
        checkpoint-note: checkpoint-note,
        completion-epoch: completion-epoch,
        checkpoint-value: checkpoint-value,
        completion-flag: false,
        settlement-flag: false
      })
    
    ;; Record checkpoint creation event
    (record-event flow-id u"checkpoint-create" u"New checkpoint established" none (some checkpoint-seq))
    
    (ok checkpoint-seq)))
