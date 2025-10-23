import { describe, it, expect, beforeEach } from "vitest";
import { Clarinet, Tx, types } from "@hirosystems/clarinet-sdk";

describe("Orchestration Engine - Workflow Coordination", () => {
  let client: any;

  beforeEach(async () => {
    const simnet = await Clarinet.connectToSimulationNetwork();
    client = simnet;
  });

  describe("Workflow Initialization & Management", () => {
    it("Should successfully create a new workflow with valid parameters", () => {
      const creator = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const response = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Q4 Product Roadmap"),
          types.utf8("Comprehensive product release planning"),
          types.uint(100),
          types.uint(500),
          types.uint(1000000)
        ],
        creator
      );

      expect(response.result).toBeOk();
    });

    it("Should allow authorized users to modify workflow configuration", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      // First create a workflow
      const createResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Integration Testing"),
          types.utf8("Full test coverage implementation"),
          types.uint(200),
          types.uint(600),
          types.uint(2000000)
        ],
        executor
      );

      const flowId = createResp.result.value;
      
      // Then modify it
      const modifyResp = client.callPublicFn(
        "orchestration-engine",
        "modify-workflow",
        [
          flowId,
          types.utf8("Updated Integration Testing"),
          types.utf8("Enhanced test coverage"),
          types.uint(2),
          types.uint(250),
          types.uint(650),
          types.uint(2500000)
        ],
        executor
      );

      expect(modifyResp.result).toBeOk();
    });

    it("Should prevent unauthorized users from modifying workflows", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      const unauthorized = "ST2QKG68FCHRD6BQZQ8N6PQ7ZCBLQQ3HX3XXWZWAP";
      
      const createResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Security Project"),
          types.utf8("Security infrastructure improvements"),
          types.uint(150),
          types.uint(550),
          types.uint(1500000)
        ],
        executor
      );

      const flowId = createResp.result.value;
      
      const modifyResp = client.callPublicFn(
        "orchestration-engine",
        "modify-workflow",
        [
          flowId,
          types.utf8("Unauthorized Modification"),
          types.utf8("Attempted unauthorized change"),
          types.uint(1),
          types.uint(200),
          types.uint(600),
          types.uint(2000000)
        ],
        unauthorized
      );

      expect(modifyResp.result).toBeErr();
    });
  });

  describe("Team Contributor Management", () => {
    it("Should allow workflow executor to enroll new contributors", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      const participant = "ST2QKG68FCHRD6BQZQ8N6PQ7ZCBLQQ3HX3XXWZWAP";
      
      const createResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Backend Development"),
          types.utf8("Core API development and deployment"),
          types.uint(100),
          types.uint(800),
          types.uint(3000000)
        ],
        executor
      );

      const flowId = createResp.result.value;
      
      const enrollResp = client.callPublicFn(
        "orchestration-engine",
        "enroll-contributor",
        [
          flowId,
          types.principal(participant),
          types.uint(2)
        ],
        executor
      );

      expect(enrollResp.result).toBeOk();
    });

    it("Should prevent duplicate enrollment of the same contributor", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      const participant = "ST2QKG68FCHRD6BQZQ8N6PQ7ZCBLQQ3HX3XXWZWAP";
      
      const createResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Frontend Engineering"),
          types.utf8("UI/UX implementation and testing"),
          types.uint(120),
          types.uint(700),
          types.uint(2500000)
        ],
        executor
      );

      const flowId = createResp.result.value;
      
      // First enrollment
      client.callPublicFn(
        "orchestration-engine",
        "enroll-contributor",
        [
          flowId,
          types.principal(participant),
          types.uint(3)
        ],
        executor
      );

      // Attempt duplicate enrollment
      const duplicateResp = client.callPublicFn(
        "orchestration-engine",
        "enroll-contributor",
        [
          flowId,
          types.principal(participant),
          types.uint(3)
        ],
        executor
      );

      expect(duplicateResp.result).toBeErr();
    });

    it("Should allow permission tier adjustment for existing contributors", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      const member = "ST2QKG68FCHRD6BQZQ8N6PQ7ZCBLQQ3HX3XXWZWAP";
      
      const createResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Data Analytics"),
          types.utf8("Business intelligence and reporting"),
          types.uint(180),
          types.uint(900),
          types.uint(1800000)
        ],
        executor
      );

      const flowId = createResp.result.value;
      
      client.callPublicFn(
        "orchestration-engine",
        "enroll-contributor",
        [
          flowId,
          types.principal(member),
          types.uint(3)
        ],
        executor
      );

      const adjustResp = client.callPublicFn(
        "orchestration-engine",
        "adjust-contributor-role",
        [
          flowId,
          types.principal(member),
          types.uint(2)
        ],
        executor
      );

      expect(adjustResp.result).toBeOk();
    });

    it("Should allow removal of contributors from workflow", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      const contributor = "ST2QKG68FCHRD6BQZQ8N6PQ7ZCBLQQ3HX3XXWZWAP";
      
      const createResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Marketing Campaign"),
          types.utf8("Q4 marketing initiatives and outreach"),
          types.uint(160),
          types.uint(750),
          types.uint(1200000)
        ],
        executor
      );

      const flowId = createResp.result.value;
      
      client.callPublicFn(
        "orchestration-engine",
        "enroll-contributor",
        [
          flowId,
          types.principal(contributor),
          types.uint(3)
        ],
        executor
      );

      const removeResp = client.callPublicFn(
        "orchestration-engine",
        "remove-contributor",
        [
          flowId,
          types.principal(contributor)
        ],
        executor
      );

      expect(removeResp.result).toBeOk();
    });

    it("Should prevent removal of workflow executor from the team", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("DevOps Infrastructure"),
          types.utf8("Cloud infrastructure and deployment"),
          types.uint(140),
          types.uint(850),
          types.uint(2700000)
        ],
        executor
      );

      const flowId = createResp.result.value;
      
      const removeResp = client.callPublicFn(
        "orchestration-engine",
        "remove-contributor",
        [
          flowId,
          types.principal(executor)
        ],
        executor
      );

      expect(removeResp.result).toBeErr();
    });
  });

  describe("Task Operations & State Transitions", () => {
    it("Should create a task within a workflow", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("System Architecture"),
          types.utf8("Microservices architecture design"),
          types.uint(100),
          types.uint(500),
          types.uint(1000000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const createTaskResp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Design API Specification"),
          types.utf8("Create comprehensive REST API documentation"),
          types.some(types.principal(executor)),
          types.uint(1),
          types.uint(16),
          types.uint(120),
          types.uint(140),
          types.none()
        ],
        executor
      );

      expect(createTaskResp.result).toBeOk();
    });

    it("Should update task details", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Mobile App Release"),
          types.utf8("Production release preparation"),
          types.uint(110),
          types.uint(550),
          types.uint(1500000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const createTaskResp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Performance Testing"),
          types.utf8("Load testing and optimization"),
          types.some(types.principal(executor)),
          types.uint(2),
          types.uint(24),
          types.uint(150),
          types.uint(180),
          types.none()
        ],
        executor
      );

      const taskId = createTaskResp.result.value;
      
      const reviseResp = client.callPublicFn(
        "orchestration-engine",
        "revise-task",
        [
          flowId,
          taskId,
          types.utf8("Extended Performance Testing"),
          types.utf8("Comprehensive load and stress testing"),
          types.some(types.principal(executor)),
          types.uint(2),
          types.uint(32),
          types.uint(140),
          types.uint(200),
          types.none()
        ],
        executor
      );

      expect(reviseResp.result).toBeOk();
    });

    it("Should transition task through workflow states", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Database Migration"),
          types.utf8("Legacy database transition project"),
          types.uint(130),
          types.uint(650),
          types.uint(2000000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const createTaskResp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Schema Design"),
          types.utf8("New database schema and optimization"),
          types.some(types.principal(executor)),
          types.uint(1),
          types.uint(20),
          types.uint(160),
          types.uint(190),
          types.none()
        ],
        executor
      );

      const taskId = createTaskResp.result.value;
      
      // Transition to active
      const activeResp = client.callPublicFn(
        "orchestration-engine",
        "transition-task-state",
        [
          flowId,
          taskId,
          types.uint(2)
        ],
        executor
      );

      expect(activeResp.result).toBeOk();

      // Transition to review
      const reviewResp = client.callPublicFn(
        "orchestration-engine",
        "transition-task-state",
        [
          flowId,
          taskId,
          types.uint(3)
        ],
        executor
      );

      expect(reviewResp.result).toBeOk();

      // Transition to done
      const doneResp = client.callPublicFn(
        "orchestration-engine",
        "transition-task-state",
        [
          flowId,
          taskId,
          types.uint(4)
        ],
        executor
      );

      expect(doneResp.result).toBeOk();
    });
  });

  describe("Task Dependencies & Prerequisites", () => {
    it("Should establish task prerequisites", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Release Pipeline"),
          types.utf8("Complete release workflow automation"),
          types.uint(170),
          types.uint(800),
          types.uint(2800000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const task1Resp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Code Review"),
          types.utf8("Peer code review and approval"),
          types.some(types.principal(executor)),
          types.uint(2),
          types.uint(8),
          types.uint(200),
          types.uint(210),
          types.none()
        ],
        executor
      );

      const task1Id = task1Resp.result.value;
      
      const task2Resp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Merge and Deploy"),
          types.utf8("Merge to main and deploy to staging"),
          types.some(types.principal(executor)),
          types.uint(1),
          types.uint(4),
          types.uint(220),
          types.uint(225),
          types.none()
        ],
        executor
      );

      const task2Id = task2Resp.result.value;
      
      const prereqResp = client.callPublicFn(
        "orchestration-engine",
        "establish-prerequisite",
        [
          flowId,
          task2Id,
          task1Id
        ],
        executor
      );

      expect(prereqResp.result).toBeOk();
    });

    it("Should prevent circular task dependencies", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("CI/CD Pipeline"),
          types.utf8("Continuous integration and delivery"),
          types.uint(145),
          types.uint(720),
          types.uint(2200000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const taskResp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Run Tests"),
          types.utf8("Execute automated test suite"),
          types.some(types.principal(executor)),
          types.uint(1),
          types.uint(6),
          types.uint(230),
          types.uint(240),
          types.none()
        ],
        executor
      );

      const taskId = taskResp.result.value;
      
      const circularResp = client.callPublicFn(
        "orchestration-engine",
        "establish-prerequisite",
        [
          flowId,
          taskId,
          taskId
        ],
        executor
      );

      expect(circularResp.result).toBeErr();
    });

    it("Should allow removal of task prerequisites", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Documentation Project"),
          types.utf8("Technical documentation creation"),
          types.uint(155),
          types.uint(680),
          types.uint(1900000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const task1Resp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Write API Docs"),
          types.utf8("Document all API endpoints"),
          types.some(types.principal(executor)),
          types.uint(1),
          types.uint(12),
          types.uint(250),
          types.uint(265),
          types.none()
        ],
        executor
      );

      const task1Id = task1Resp.result.value;
      
      const task2Resp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Generate SDK"),
          types.utf8("Generate SDK from API documentation"),
          types.some(types.principal(executor)),
          types.uint(2),
          types.uint(16),
          types.uint(270),
          types.uint(290),
          types.none()
        ],
        executor
      );

      const task2Id = task2Resp.result.value;
      
      client.callPublicFn(
        "orchestration-engine",
        "establish-prerequisite",
        [
          flowId,
          task2Id,
          task1Id
        ],
        executor
      );

      const removeResp = client.callPublicFn(
        "orchestration-engine",
        "sever-prerequisite",
        [
          flowId,
          task2Id,
          task1Id
        ],
        executor
      );

      expect(removeResp.result).toBeOk();
    });
  });

  describe("Work Artifacts & Time Tracking", () => {
    it("Should attach work artifacts to tasks", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Design System"),
          types.utf8("Component library and design tokens"),
          types.uint(175),
          types.uint(750),
          types.uint(1600000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const createTaskResp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Create Component Library"),
          types.utf8("Build reusable component library"),
          types.some(types.principal(executor)),
          types.uint(2),
          types.uint(40),
          types.uint(300),
          types.uint(350),
          types.none()
        ],
        executor
      );

      const taskId = createTaskResp.result.value;
      
      const artifactHash = "0x" + "a".repeat(64);
      
      const attachResp = client.callPublicFn(
        "orchestration-engine",
        "attach-work-artifact",
        [
          flowId,
          taskId,
          types.buff(Buffer.from(artifactHash.slice(2), "hex"))
        ],
        executor
      );

      expect(attachResp.result).toBeOk();
    });

    it("Should record time entries on tasks", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Training Program"),
          types.utf8("Team training and skill development"),
          types.uint(165),
          types.uint(600),
          types.uint(1400000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const createTaskResp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Conduct Workshops"),
          types.utf8("Technical workshops and training sessions"),
          types.some(types.principal(executor)),
          types.uint(1),
          types.uint(20),
          types.uint(360),
          types.uint(380),
          types.none()
        ],
        executor
      );

      const taskId = createTaskResp.result.value;
      
      const timeResp = client.callPublicFn(
        "orchestration-engine",
        "log-task-time",
        [
          flowId,
          taskId,
          types.uint(8),
          types.utf8("Day 1 training session")
        ],
        executor
      );

      expect(timeResp.result).toBeOk();
    });

    it("Should add notes to tasks", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Support Engineering"),
          types.utf8("Customer support and issue resolution"),
          types.uint(135),
          types.uint(580),
          types.uint(1100000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const createTaskResp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Resolve Critical Bugs"),
          types.utf8("Address and fix critical issues"),
          types.some(types.principal(executor)),
          types.uint(2),
          types.uint(12),
          types.uint(400),
          types.uint(415),
          types.none()
        ],
        executor
      );

      const taskId = createTaskResp.result.value;
      
      const noteResp = client.callPublicFn(
        "orchestration-engine",
        "compose-task-note",
        [
          flowId,
          taskId,
          types.utf8("Identified root cause in authentication module")
        ],
        executor
      );

      expect(noteResp.result).toBeOk();
    });
  });

  describe("Checkpoint Management", () => {
    it("Should create checkpoints for workflow milestones", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Multi-Phase Project"),
          types.utf8("Large scale project with multiple phases"),
          types.uint(125),
          types.uint(1000),
          types.uint(5000000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const checkpointResp = client.callPublicFn(
        "orchestration-engine",
        "create-workflow-checkpoint",
        [
          flowId,
          types.utf8("Alpha Release"),
          types.utf8("First public release candidate"),
          types.uint(450),
          types.uint(100000)
        ],
        executor
      );

      expect(checkpointResp.result).toBeOk();
    });

    it("Should retrieve checkpoint information", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Staged Rollout"),
          types.utf8("Phased deployment strategy"),
          types.uint(135),
          types.uint(950),
          types.uint(4500000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const checkpointResp = client.callPublicFn(
        "orchestration-engine",
        "create-workflow-checkpoint",
        [
          flowId,
          types.utf8("Beta Release"),
          types.utf8("Second release phase"),
          types.uint(500),
          types.uint(150000)
        ],
        executor
      );

      const checkpointId = checkpointResp.result.value;
      
      const queryResp = client.callReadOnlyFn(
        "orchestration-engine",
        "query-checkpoint",
        [
          flowId,
          checkpointId
        ]
      );

      expect(queryResp.result).toBeOk();
    });
  });

  describe("Query Operations & Read-Only Functions", () => {
    it("Should retrieve workflow details through query function", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Query Test Workflow"),
          types.utf8("Testing query functionality"),
          types.uint(105),
          types.uint(520),
          types.uint(950000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const queryResp = client.callReadOnlyFn(
        "orchestration-engine",
        "query-workflow",
        [flowId]
      );

      expect(queryResp.result).toBeOk();
    });

    it("Should check team member status", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      const member = "ST2QKG68FCHRD6BQZQ8N6PQ7ZCBLQQ3HX3XXWZWAP";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Team Status Check"),
          types.utf8("Verifying team membership queries"),
          types.uint(115),
          types.uint(540),
          types.uint(1050000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      client.callPublicFn(
        "orchestration-engine",
        "enroll-contributor",
        [
          flowId,
          types.principal(member),
          types.uint(3)
        ],
        executor
      );
      
      const statusResp = client.callReadOnlyFn(
        "orchestration-engine",
        "has-team-access",
        [
          flowId,
          types.principal(member)
        ]
      );

      expect(statusResp.result).toBeOk();
    });

    it("Should retrieve user permission tier", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      const member = "ST2QKG68FCHRD6BQZQ8N6PQ7ZCBLQQ3HX3XXWZWAP";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Permission Tier Test"),
          types.utf8("Validating permission tier queries"),
          types.uint(125),
          types.uint(560),
          types.uint(1150000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      client.callPublicFn(
        "orchestration-engine",
        "enroll-contributor",
        [
          flowId,
          types.principal(member),
          types.uint(2)
        ],
        executor
      );
      
      const tierResp = client.callReadOnlyFn(
        "orchestration-engine",
        "query-permission-tier",
        [
          flowId,
          types.principal(member)
        ]
      );

      expect(tierResp.result).toBeOk();
    });

    it("Should retrieve task information", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Task Query Test"),
          types.utf8("Testing task information retrieval"),
          types.uint(105),
          types.uint(480),
          types.uint(850000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const createTaskResp = client.callPublicFn(
        "orchestration-engine",
        "spawn-task",
        [
          flowId,
          types.utf8("Sample Task"),
          types.utf8("For testing query functionality"),
          types.some(types.principal(executor)),
          types.uint(1),
          types.uint(8),
          types.uint(500),
          types.uint(515),
          types.none()
        ],
        executor
      );

      const taskId = createTaskResp.result.value;
      
      const queryResp = client.callReadOnlyFn(
        "orchestration-engine",
        "query-task",
        [
          flowId,
          taskId
        ]
      );

      expect(queryResp.result).toBeOk();
    });
  });

  describe("Edge Cases & Error Handling", () => {
    it("Should handle non-existent workflow queries gracefully", () => {
      const queryResp = client.callReadOnlyFn(
        "orchestration-engine",
        "query-workflow",
        [types.uint(99999)]
      );

      expect(queryResp.result).toBeNone();
    });

    it("Should prevent operations on non-existent workflows", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      const member = "ST2QKG68FCHRD6BQZQ8N6PQ7ZCBLQQ3HX3XXWZWAP";
      
      const enrollResp = client.callPublicFn(
        "orchestration-engine",
        "enroll-contributor",
        [
          types.uint(99999),
          types.principal(member),
          types.uint(3)
        ],
        executor
      );

      expect(enrollResp.result).toBeErr();
    });

    it("Should reject invalid permission tier values", () => {
      const executor = "ST1PQHQV0PM9461XCJVE4XRA2VXEMAS8YFZWYJGR";
      const member = "ST2QKG68FCHRD6BQZQ8N6PQ7ZCBLQQ3HX3XXWZWAP";
      
      const createWfResp = client.callPublicFn(
        "orchestration-engine",
        "initialize-workflow",
        [
          types.utf8("Permission Test"),
          types.utf8("Testing permission validation"),
          types.uint(115),
          types.uint(475),
          types.uint(800000)
        ],
        executor
      );

      const flowId = createWfResp.result.value;
      
      const enrollResp = client.callPublicFn(
        "orchestration-engine",
        "enroll-contributor",
        [
          flowId,
          types.principal(member),
          types.uint(99)
        ],
        executor
      );

      expect(enrollResp.result).toBeErr();
    });
  });
});
