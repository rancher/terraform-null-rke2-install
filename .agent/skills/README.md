# AI Agent Skills

This directory contains reusable tools or scripts that AI agents can recommend or utilize to execute tasks in this repository.

Examples include scripts for running acceptance tests (`run-acc-test.sh`), linting code, or automating repetitive tasks.

## Skill Maintenance Rule

If you are an AI agent attempting to use a skill in this directory and you find that it is broken, out of date, or lacking proper execution permissions:
1. **You MUST proactively fix the skill.**
2. If it is a permission issue (e.g., `Permission denied`), use `chmod +x` AND `git update-index --chmod=+x` to permanently fix the tracked permissions.
3. If it is a logic or environment issue, debug and update the script so that it works correctly for future use.
