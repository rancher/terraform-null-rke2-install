# Workflow: Troubleshooting CI/CD Workflows

This workflow defines the procedure that AI agents must follow when investigating, diagnosing, and resolving broken GitHub Actions CI/CD pipelines.

## Phase 1: Log Retrieval & Triage

### 1. Fetch Workflow Logs
* Use the log retrieval skill (`.agent/skills/pull-ci-logs.sh`) to download the logs from the failed run:
  ```bash
  .agent/skills/pull-ci-logs.sh -w <workflow-name> -s failure --failed-only
  ```
* Inspect the tail of the log file or search for critical errors to isolate the failing job and step.

### 2. Reproduce Environment Settings
* Examine the failing job's container image and step environment variables.
* Identify if the failure is code-related, script-related, or infrastructure-related (e.g., missing API secrets, network failures, or GPG agent lockups).

---

## Phase 2: Script & Configuration Audit

### 1. Analyze Scripts & YAMLs
* Check the workflow YAML files (`.github/workflows/*.{yml,yaml}`) to understand the step configuration.
* Ensure all scripts invoked by the failing steps actually exist and are executable.
* Review script contents for standard safety flags (`set -euo pipefail` in Bash) and error handling.

### 2. Trim & Sanitize Inputs
* Check if inputs retrieved from Vault or GitHub Secrets contain hidden characters, carriage returns (`\r`), or trailing newlines (`\n`).
* Apply defensive sanitization (such as `tr -d '[:space:]'`) in utility scripts to guarantee GPG, Git, or API keys are clean before use.

---

## Phase 3: Planning & Strategy

### 1. Formulate the Fix
* Design a clean correction (e.g. updating a script path, patching a variable trim, or updating GPG flags).
* Avoid quick-and-dirty hacks (like bypassing static checks or disabling safety flags) unless explicitly requested.

### 2. Document the Resolution Plan
* Write a plan file under `.agent/plans/` and a checklist in `.agent/agent-memory/` detailing what needs to be changed.
* Get approval from the user before applying edits.

---

## Phase 4: Local Dry-Run & Validation

### 1. Static Validation
* Run local linters to check the validity of your scripts and workflows:
  * For Shell scripts: `shellcheck <script>`
  * For Workflow YAML files: `actionlint <workflow>`

### 2. Verify Fix Locally
* Test script execution path adjustments locally without committing or pushing, utilizing dry-run flags where possible.

---

## Phase 5: Finalization & Recap

### 1. Summary of Resolution
* Once the fix is applied and verified, provide a detailed technical analysis of:
  * What caused the failure (the root cause).
  * How the fix addresses the root cause.
  * Which quality gates (like `actionlint` or `shellcheck`) were used to verify correctness.
