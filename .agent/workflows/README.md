# AI Agent Workflows

This directory contains defined, step-by-step procedures that AI agents must follow when executing complex, multi-step tasks in this repository. 

Using these workflows ensures maximum consistency, rigorous quality control, and clean engineering practices.

## Available Workflows

### 1. [Standard Development Process](development-process.md)
* **Purpose:** Outlines the lifecycle for developing new features, applying bug fixes, and performing refactoring.
* **Key Steps:** Exploration, bug reproduction, plan-creation, surgical edits, format/compiles, unit testing, schema documentation updates, and lint validations.

### 2. [Troubleshooting CI/CD Workflows](troubleshoot-workflows.md)
* **Purpose:** Explains how to diagnose, triage, and repair broken GitHub Actions or release workflows.
* **Key Steps:** Log retrieval, error isolation, script/YAML auditing, secret token sanitization, and verification with `actionlint` and `shellcheck`.

### 3. [Test Troubleshooting Process](test-troubleshooting.md)
* **Purpose:** Outlines the step-by-step loop for triaging Go integration test failures and capturing rich Terraform JSON logs.
* **Key Steps:** Multi-test execution, parsing logs, individual sequential triage, unified plan creation, and user approval loops.
