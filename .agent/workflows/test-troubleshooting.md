# Workflow: Test Troubleshooting Process

This workflow defines the defined, step-by-step procedure that AI agents must follow when executing, triaging, and debugging test suite failures in this repository.

## Phase 1: Test Suite Execution & Result Verification

### 1. Run the Full Test Suite
* Execute the test suite using the `run-tests` skill to capture both test outputs and detailed Terraform JSON logs:
  ```bash
  .agent/skills/run-tests.sh -o test_run.log -l terraform_json.log
  ```
* Dynamically monitor and poll the progress of the active test run by launching the `watch-tests` skill on the test runner process:
  ```bash
  .agent/skills/watch-tests.sh -p <PID> -f test_run.log
  ```

### 2. Verify and Parse Results
* Inspect the last 100 lines of the stdout test run log (`test_run.log`), where test results are summarized, to determine if all tests passed.
* If any tests failed, parse `test_run.log` to compile a list of all failing test names (e.g. `TestBasic`, `TestManifest`).

---

## Phase 2: Sequential Failure Triage

If one or more tests fail, follow this sequential execution loop to isolate errors:

### 1. Execute Failed Tests Individually
* For **each** identified failed test, run it in isolation using the `run-tests` skill to capture a dedicated, clean set of log files for that test:
  ```bash
  .agent/skills/run-tests.sh -t <FailedTestName> -o <FailedTestName>_run.log -l <FailedTestName>_tf.json
  ```
* Dynamically monitor the individual run using the `watch-tests` skill:
  ```bash
  .agent/skills/watch-tests.sh -p <PID> -f <FailedTestName>_run.log
  ```

### 2. Parse Log Files for Specific Errors
* Parse both the test stdout log (`<FailedTestName>_run.log`) and the rich Terraform JSON logs (`<FailedTestName>_tf.json`) for:
  * **Test runner errors**: Go panicked, AWS KeyPair failures, or SSH configuration timeouts.
  * **Terraform compile/plan errors**: Undeclared variables, missing provider definitions, or validation precondition failures.
  * **Terraform apply/runtime errors**: SSH connect failures, remote-exec exit code failures, or AWS resource state mismatches.

### 3. Build a Targeted Resolution Strategy
* For the current failing test, write down the specific root cause and draft a code-level or configuration-level fix to resolve it.
* Do **not** apply any code modifications yet.

---

## Phase 3: Unified Plan Formulation & User Feedback

After triaging all failed tests individually:

### 1. Formulate a Single Consolidated Plan
* Aggregate all of the individual resolution strategies into a **single, unified resolution plan**. 
* Even if multiple separate tests failed with completely different errors, compile them into one comprehensive plan file under `.agent/plans/` (e.g. `.agent/plans/TestFailureResolution_July2026.md`) and create a tracking checklist in `.agent/agent-memory/`.

### 2. Request User Approval
* Stop and present the consolidated resolution plan to the user.
* Provide a clear, detailed explanation of:
  * Which tests failed.
  * The specific root causes found for each failure from log parsing.
  * The unified plan to resolve all failures cleanly.
* **Wait for explicit user approval/feedback before modifying any source, configuration, or test files.**
