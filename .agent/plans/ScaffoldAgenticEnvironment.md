# Agentic Environment Setup Plan

**Date Completed:** Pending
**Purpose:** Provide a reproducible blueprint for scaffolding a unified, cross-platform AI agentic environment in any new or existing repository.

This plan details the steps an AI assistant should take to generate the foundational configuration files and directory structures required to align GitHub Copilot, Claude, and Gemini under a single set of architectural rules.

When acting as an AI assistant executing this plan in a new repository, follow each phase thoroughly to create the files and directories described below.

---

## Phase 1: Create Root Routing Files
**Objective**: Establish the entry points for all supported AI platforms that redirect them to a single source of truth.

1.  **Create `GEMINI.md`** (Root directory):
    *   This file tells Gemini CLI where to find the source of truth.
    *   **Content:**
        ```markdown
        # Gemini Context Pointer

        You are assisting with development in this workspace. 

        Your absolute source of truth for all architectural decisions, coding standards, and repository rules is the `AGENTS.md` file located in the root directory. 

        Before suggesting code edits, writing new functions, or answering architectural questions, you MUST read `AGENTS.md` to understand the project's constraints and locate the specific instruction files for the language you are working with.

        It contains essential coding standards, the `.agent` directory structure you need to use, and strict rules specific to your role in this project.
        ```

2.  **Create `CLAUDE.md`** (Root directory):
    *   This file tells Claude where to find the source of truth.
    *   **Content:**
        ```markdown
        You are an AI assistant working on this project.
        Before making any code suggestions or analyzing the repo, you MUST read `AGENTS.md` in the root of this repository for your complete instructions.

        It contains essential coding standards, the `.agent` directory structure you need to use, and strict rules specific to your role in this project.
        ```

3.  **Create `.github/copilot-instructions.md`**:
    *   This file provides repository-level instructions for GitHub Copilot.
    *   **Content:**
        ```markdown
        # GitHub Copilot Instructions

        Before analyzing this repository, providing code suggestions, or reviewing pull requests, you MUST read the authoritative root prompt for all agents located in `AGENTS.md` at the root of this repository.

        It contains essential coding standards, the `.agent` directory structure you need to use, and strict rules specific to your role in this project.
        ```

---

## Phase 2: Create the Master Instructions File
**Objective**: Define the overarching rules, environment directives, and directory mappings in `AGENTS.md`.

1.  **Create `AGENTS.md`** (Root directory):
    *   **Content:**
        ```markdown
        # System Instructions & Agent Protocols

        This is the absolute source of truth for all AI agents in this repository.
        Comply with role-specific directives.

        ## 1. Environment Directives

        * **Permissions:** Read files/folders as needed without asking.
        * *(Add repository-specific environment setup instructions here, e.g., Nix, Docker, etc.)*

        ## 2. Agent Personas & Contexts

        Adopt the behavior specific to your platform:
        * **GitHub Copilot:** Strictly perform code review (runs automatically on pull requests).
        * **Claude:** Operate in agentic programming mode. Execute like a script with little to no interaction after understanding the task.
        * **Gemini:** Act as a conversational coding assistant and partner. Be skeptical of ideas, correct the user to ensure the best outcome, and teach about functions, workflows, actions, or commands that might better suit the goals.

        ## 3. Planning Protocol

        All agents MUST plan their work before executing.
        After user refinement, record final plans as markdown files in `.agent/plans/`.
        * **Executed Date:** Include an "executed date" (or "pending") to build a timeline.
        * **Purpose:** Acts as project requirements (new repos) or provides historical context for future decisions (legacy repos).

        ## 4. Directory Structure Mapping

        The root `.agent/` directory contains tools and context for all agents.

        * **Claude:** Treat `.agent/` exactly like `.claude/`. Subdirectories function natively.
        * **GitHub Copilot:** Map `.agent/rules` -> `.github/instructions`, `.agent/skills` -> `.github/skills`, and `.agent/agents` -> `.github/agents`.
        * **Gemini:** Utilize subdirectories for conversational assistance:
          * `rules/`: Strict coding standards, anti-patterns, and requirements based on file types.
          * `skills/`: Reusable tools or scripts you can recommend or utilize.
          * `agents/`: Specialized agent definitions and prompts.
          * `output-styles/`: Guidelines on how to format your responses.
          * `workflows/`: Defined processes for executing multi-step tasks.
          * `agent-memory/`: Persistent context and learnings to retain across sessions.
          * `plans/`: Context on historic decisions and major refactors.

        ## 5. Required Coding Standards

        Consult and adhere to these rule files when generating, editing, or reviewing code:
        *(Add repository-specific language mappings here, e.g., `**/*.go` -> `.agent/rules/go.instructions.md`)*
        ```

---

## Phase 3: Scaffold the `.agent` Directory Structure
**Objective**: Build out the structured folders that hold granular context, rules, and workflows.

1.  **Create Directories**:
    *   `.agent/agent-memory/`
    *   `.agent/agents/`
    *   `.agent/output-styles/`
    *   `.agent/plans/`
    *   `.agent/rules/`
    *   `.agent/skills/`
    *   `.agent/workflows/`

2.  **Create `README.md` files for each subdirectory**:

    *   **`.agent/agent-memory/README.md`**:
        ```markdown
        # Agent Memory
        Persistent context and learnings to retain across sessions.
        ```
    *   **`.agent/agents/README.md`**:
        ```markdown
        # Specialized AI Agents
        This directory contains specialized agent definitions and prompts. 
        These files can be used to set the context, persona, and specific capabilities for different AI agents operating within the repository.
        ```
    *   **`.agent/output-styles/README.md`**:
        ```markdown
        # AI Output Styles
        This directory contains guidelines on how AI agents should format their responses.
        Rules here ensure that code suggestions, pull request reviews, and conversational assistance maintain a consistent and readable structure.
        ```
    *   **`.agent/plans/README.md`**:
        ```markdown
        # Plans
        Context on historic decisions, major refactors, and executed or pending plans.
        ```
    *   **`.agent/rules/README.md`**:
        ```markdown
        # AI Agent Rules
        This directory contains strict coding standards, anti-patterns, and requirements based on file types. 
        AI agents MUST consult the corresponding instruction file in this directory whenever asked to generate, edit, or review code.
        ```
    *   **`.agent/skills/README.md`**:
        ```markdown
        # AI Agent Skills
        This directory contains reusable tools or scripts that AI agents can recommend or utilize to execute tasks in this repository.
        ```
    *   **`.agent/workflows/README.md`**:
        ```markdown
        # AI Agent Workflows
        This directory contains defined processes for executing multi-step tasks.
        These workflows provide step-by-step procedures for AI agents to follow when tackling complex tasks.
        ```

---

## Phase 4: Populate Initial Base Files (Optional / Repository-Specific)
**Objective**: Fill the `.agent` structure with initial configuration suited for the new project.

1.  **Output Styles**:
    *   Create `.agent/output-styles/claude-strict.md` or `.agent/output-styles/gemini-conversational.md` as needed.
2.  **Rules**:
    *   Create language-specific instruction files (e.g., `go.instructions.md`, `python.instructions.md`, `workflows.instructions.md`) inside `.agent/rules/`.
3.  **Skills**:
    *   Add any common bash scripts for formatting, testing, or linting (e.g., `run-tests.sh`) to `.agent/skills/`.
4.  **Workflows**:
    *   Add step-by-step instructions for PR creation, releases, or CI fixes into `.agent/workflows/`.
