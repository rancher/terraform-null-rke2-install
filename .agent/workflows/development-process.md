# Workflow: Standard Development Process

This workflow defines the standard, step-by-step procedure that all AI agents must follow when implementing features, refactoring code, or fixing bugs in this repository.

## Phase 1: Research & Reproduce

### 1. Codebase Exploration
* Search the codebase for existing design patterns, helper functions, and architectural conventions.
* Identify all files affected by the requested change (both source and tests).
* Reference the language-specific standard rules under `.agent/rules/` (such as `go.instructions.md` or `terraform.instructions.md`).

### 2. Empirical Bug Reproduction (Mandatory for Bug Fixes)
* Before writing any fix, you must reproduce the reported failure state.
* Write a localized test case or a reproduction script that demonstrates the bug.
* Run the reproduction to confirm it fails exactly as described.

---

## Phase 2: Strategy & Planning

### 1. Formulate Plan
* Design a modular, robust solution that integrates cleanly with the existing architecture.
* Prioritize explicit composition over complex inheritance.

### 2. Document the Plan
* Record a high-level plan under `.agent/plans/<PlanName>.md` (if the change is substantial—such as modifying 5+ files or >300 lines of code).
* Always build a temporary checklist plan under `.agent/agent-memory/<PlanName>_temp.md` to track progress across sessions.
* Present the plan to the user for approval before modifying files.

---

## Phase 3: Surgical Implementation (Act)

### 1. Apply Changes
* Apply targeted, precise edits to source files.
* Do not perform unrelated refactoring or "cleanups" outside of the scope of the approved plan.
* Keep edits simple, readable, and idiomatic.

### 2. Format & Compilation
* Run ecosystem formatters (e.g. `go fmt`) immediately after editing.
* Compile the project locally to verify there are no syntax or type errors.

---

## Phase 4: Testing & Documentation (Validate)

### 1. Test Verification
* Always add new automated test cases to cover the modified or new logic.
* Run unit tests to confirm correctness:
  ```bash
  ./run_tests.sh -t <TestName>
  ```
* Run local acceptance tests (excluding AWS test relay unless explicitly instructed).

### 2. Update Documentation
* If schemas, parameters, or behaviors have changed, update the markdown documentation under `docs/resources/` or `docs/data-sources/` accordingly.

---

## Phase 5: Code Quality & Finalization

### 1. Lint & Static Analysis
* Run local linters (e.g. `golangci-lint`) to ensure code compliance.
* Resolve any static analysis warnings.

### 2. Summary
* Provide a concise summary of the changes made, the tests executed, and the results achieved against the plan.
