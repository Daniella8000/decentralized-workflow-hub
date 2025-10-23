# Decentralized Workflow Hub

A next-generation workflow orchestration platform built on Stacks blockchain for coordinating distributed team operations with cryptographic transparency and immutable execution records.

## Vision

Decentralized Workflow Hub (DWH) reimagines how distributed teams collaborate on complex initiatives by anchoring workflow coordination directly on-chain. Rather than relying on centralized systems, teams benefit from:

- **Transparent Operations**: Every workflow action is timestamped and tamper-proof on the blockchain
- **Permission-Based Collaboration**: Fine-grained control over who can perform what actions
- **Checkpoint-Driven Milestones**: Track progress through defined workflow stages with payment triggers
- **Time & Artifact Tracking**: Comprehensive logging of work artifacts and time investment across tasks
- **Dependency Resolution**: Prevent workflow bottlenecks by enforcing task prerequisite chains

## Core Capabilities

The Decentralized Workflow Hub provides enterprises with:

- **Workflow Orchestration**: Create, configure, and manage complex multi-task workflows
- **Team Collaboration**: Enroll contributors with granular permission tiers
- **Task Management**: Full lifecycle management from idle through completion states
- **Audit Trail**: Immutable event logging for compliance and transparency
- **Checkpoint Framework**: Define and track milestone deliverables with settlement amounts
- **Time Ledger**: Distributed time tracking with contributor attribution
- **Artifact Management**: Cryptographic verification of deliverables via content hashing

## System Architecture

```
┌─────────────────────────────────────────────────┐
│          Orchestration Engine (Smart Contract)   │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐    ┌──────────────┐         │
│  │ Workflows    │    │ Checkpoints  │         │
│  │ (State Mgmt) │    │ (Milestones) │         │
│  └──────────────┘    └──────────────┘         │
│                                                 │
│  ┌──────────────┐    ┌──────────────┐         │
│  │ Tasks        │    │ Team Members │         │
│  │ (W/ Deps)    │    │ (Roles)      │         │
│  └──────────────┘    └──────────────┘         │
│                                                 │
│  ┌──────────────┐    ┌──────────────┐         │
│  │ Time Entries │    │ Artifacts    │         │
│  │ (Tracking)   │    │ (Hashes)     │         │
│  └──────────────┘    └──────────────┘         │
│                                                 │
│  ┌──────────────────────────────────┐         │
│  │      Audit Event Log             │         │
│  │    (Immutable Record Trail)      │         │
│  └──────────────────────────────────┘         │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Permission Framework

The system implements a four-tier permission model:

| Tier | Role | Capabilities |
|------|------|--------------|
| **1** | **Executor** | Full workflow control, member management, configuration changes |
| **2** | **Overseer** | Team management, task structuring, workflow adjustments |
| **3** | **Contributor** | Task creation, time logging, artifact submission, commenting |
| **4** | **Observer** | Read-only access, no modification capabilities |

## Getting Started

### Prerequisites

- Clarinet (v2.1+)
- Node.js (v16+)
- Stacks-enabled wallet

### Installation & Setup

1. **Clone repository**
   ```bash
   git clone <repository>
   cd decentralized-workflow-hub
   ```

2. **Install dependencies**
   ```bash
   clarinet install
   npm install
   ```

3. **Run test suite**
   ```bash
   npm run test
   ```

4. **Start local development**
   ```bash
   clarinet integrate
   ```

## Contract Functions

### Workflow Operations

#### Initialize Workflow
Creates a new workflow container with executor as primary stakeholder.

```clarity
(initialize-workflow 
  workflow-name 
  flow-description 
  epoch-start 
  epoch-end 
  allocated-budget)
```

#### Modify Workflow
Updates workflow configuration with authorization check.

```clarity
(modify-workflow 
  flow-id 
  workflow-name 
  flow-description 
  execution-state 
  epoch-start 
  epoch-end 
  allocated-budget)
```

### Team Management

#### Enroll Contributor
Registers a new team member with specified permission tier.

```clarity
(enroll-contributor flow-id participant permission-tier)
```

#### Adjust Contributor Role
Modifies permission tier for existing team member.

```clarity
(adjust-contributor-role flow-id participant new-permission-tier)
```

#### Remove Contributor
Revokes access for team member (cannot remove executor).

```clarity
(remove-contributor flow-id participant)
```

### Task Operations

#### Spawn Task
Creates new task within workflow with optional checkpoint assignment.

```clarity
(spawn-task 
  flow-id 
  task-name 
  task-description 
  assigned-operator 
  severity-level 
  hrs-estimated 
  epoch-begin 
  epoch-complete 
  checkpoint-ref)
```

#### Revise Task
Updates task configuration with authorization checks.

```clarity
(revise-task 
  flow-id 
  task-sequence 
  task-name 
  task-description 
  assigned-operator 
  severity-level 
  hrs-estimated 
  epoch-begin 
  epoch-complete 
  checkpoint-ref)
```

#### Transition Task State
Advances task through workflow states (IDLE → ACTIVE → REVIEW → DONE).

```clarity
(transition-task-state flow-id task-sequence new-state)
```

### Dependency Management

#### Establish Prerequisite
Links task dependencies to enforce workflow sequencing.

```clarity
(establish-prerequisite flow-id task-sequence predecessor-task)
```

#### Sever Prerequisite
Removes dependency relationship between tasks.

```clarity
(sever-prerequisite flow-id task-sequence predecessor-task)
```

### Work Tracking

#### Log Task Time
Records time investment with contributor attribution.

```clarity
(log-task-time flow-id task-sequence duration-hours entry-note)
```

#### Attach Work Artifact
Registers deliverable with content hash for verification.

```clarity
(attach-work-artifact flow-id task-sequence work-artifact-hash)
```

#### Compose Task Note
Adds collaborative notes/comments to tasks.

```clarity
(compose-task-note flow-id task-sequence note-body)
```

### Checkpoint Framework

#### Create Workflow Checkpoint
Establishes milestone with settlement amount.

```clarity
(create-workflow-checkpoint 
  flow-id 
  checkpoint-name 
  checkpoint-note 
  completion-epoch 
  checkpoint-value)
```

## Read-Only Queries

All query functions are permission-less and return available data:

```clarity
(query-workflow flow-id)              ;; Retrieve workflow details
(query-task flow-id task-sequence)    ;; Fetch task information
(query-checkpoint flow-id checkpoint-seq) ;; Get checkpoint data
(has-team-access flow-id participant) ;; Check membership
(query-permission-tier flow-id participant) ;; Get permission level
```

## Security Architecture

### Access Control
- Role-based permission checks on all state-modifying functions
- Executor status prevents unauthorized team removal
- Contributor permissions validated against operation type

### Data Integrity
- All state mutations include timestamp recording
- Circular dependency prevention (task cannot depend on itself)
- Checkpoint completion validation before marking as done

### Audit Trail
- Every operation generates immutable event record
- Event logs include actor, action type, timestamp, and references
- Enables compliance tracking and forensic analysis

### Workflow Safety
- Task prerequisites enforce operational sequencing
- Status transitions validated against business rules
- Invalid state values rejected at contract boundary

## Use Cases

### Software Development Delivery
- Manage sprint planning with checkpoint-based releases
- Track code reviews as prerequisite tasks
- Document deliverables with artifact hashing
- Attribute time spent to individual contributors

### Construction & Project Management
- Phase-based milestone tracking with payment triggers
- Equipment/resource allocation via task assignment
- Photo/documentation artifacts at completion
- Crew time logging for payroll integration

### Consulting Services
- Project scoping with checkpoint deliverables
- Consultant time tracking for billing
- Artifact submission for client review
- Dependency mapping for parallel work streams

## Development Workflow

### Running Tests
```bash
npm run test              # Single test run
npm run test:watch       # Watch mode with auto-rerun
npm run test:report      # Full report with coverage
```

### Local Testing Chain
```bash
clarinet integrate       # Start local Stacks chain
clarinet deploy         # Deploy contracts
clarinet console        # Interactive REPL
```

## Limitations & Future Enhancements

### Current Constraints
- Single executor per workflow (no multi-signature)
- No bulk operations (add multiple tasks in one tx)
- Time entries cannot be modified after submission
- No native payment settlement logic (external oracle needed)

### Roadmap
- Multi-signature executor approval
- Batch task creation endpoints
- Time entry dispute resolution
- Native STX payment settlement
- IPFS integration for large artifact storage

## Support & Community

- **Documentation**: `/docs` directory
- **Examples**: `/examples` for common workflows
- **Issues**: GitHub issue tracker
- **Discussions**: Community forum

## License

MIT - See LICENSE file for details

## Contributing

We welcome contributions! Please see CONTRIBUTING.md for guidelines.

---

**Built for teams that demand transparency, accountability, and decentralized coordination.**