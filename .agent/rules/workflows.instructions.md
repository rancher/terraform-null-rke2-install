---
applyTo: ".github/workflows/**/*.{yml,yaml}"
---

# GitHub Actions Workflow PR Review Standards

As a strict DevSecOps CI/CD reviewer, enforce these standards on all workflow changes. Flag violations with a concise explanation and provide the refactored YAML.

## 1. Security (Critical)
* **Least Privilege:** All jobs must define explicit `permissions:`. All workflows should have `permissions: {}` at the top level. Permissions should implement least privilege necessary access.
* **Pin Actions by SHA:** Pin all external actions to a full 40-character commit SHA. The `uses:` line MUST include the version inline in a comment (e.g., `# v6.0.2`). On the line before the `uses:` there should be a comment with a link to the releases page for the action (e.g. `# https://github.com/actions/github-script/releases`).
* **Prevent Script Injection:** Never inline untrusted context variables in `run` scripts. Use environment variables (e.g., `env: VAR: ${{...}}`).
* **No `pull_request_target`:** This trigger is banned.
* **FOSSA Token:** The `rancher-eio/read-vault-secrets` action is an exception to the strict pinning and should look exactly like this:
  ```yaml
    # The FOSSA token is shared between all repos in Rancher's GH org.
    # It can be used directly and there is no need to request specific access to EIO.
    - name: 'Read FOSSA Token'
      # https://github.com/rancher-eio/read-vault-secrets/commits/main/
      uses: rancher-eio/read-vault-secrets@7282bf97898cd1c16c89f837e0bb442e6d384c89 # main
      with:
        secrets: |
          secret/data/github/org/rancher/fossa/push token | FOSSA_API_KEY_PUSH_ONLY
  ```

## 2. Reliability & Performance
* **Explicit Timeouts:** Every `job` must have an explicit `timeout-minutes` set appropriately, defaulting to `30`.
* **Concurrency:** Use `concurrency` blocks in PR workflows to cancel redundant runs (e.g., `group: ${{ github.workflow }}-${{ github.ref }}`).
* **Container Environment:** Ensure all jobs use the nix ci-image container:
  ```yaml
    container:
      image: ghcr.io/rancher/ci-image/nix:20260603-18
  ```
  *Exception:* The `release.yaml` workflow MUST NOT use the `container:` block at the job level. Instead, the job runs directly on the runner and specific steps that require the Nix environment should use the `.github/workflows/scripts/run-in-nix-container.sh` script.
* **No `install-nix`:** Remove all `install-nix` steps since the container provides it natively.

## 3. Structure & Maintainability
* **Descriptive Names:** All workflows, jobs, and steps need a descriptive `name:`. When adding a name to a step, make sure to remove the dash from the previous beginning, otherwise it will be interpreted as a new step.
* **Terraform Formatting:** Terraform fmt steps need to include `-diff`: `terraform fmt -check -recursive -diff`.
* **Extract Scripts:**
  * **GitHub Scripts:** Do not use inline JavaScript in `actions/github-script`. Extract to `.js` files in `.github/workflows/scripts/` and import dynamically:
    ```typescript
      const scriptPath = `${process.env.GITHUB_WORKSPACE}/.github/workflows/scripts/my-script.js`;
      const { default: script } = await import(scriptPath);
      await script({ github, context });
    ```
  * **Bash Scripts:** Extract inline bash `run:` logic to `.sh` files in `.github/workflows/scripts/` and pipe through `nix-run.sh` (e.g., `bash .github/workflows/scripts/nix-run.sh "bash .github/workflows/scripts/my-script.sh"`).
* **Environment Protection:** Jobs with production secrets must use an `environment:` block for manual approval.

## Review Constraints
* Ignore basic YAML formatting unless it's a syntax error.
* Provide the exact refactored YAML block in your recommendation.
