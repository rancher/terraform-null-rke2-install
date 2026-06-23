# Repository Update & Refactoring Plan

Date Completed: June 2026
This document outlines the strict execution plan for upgrading and standardizing this repository.
When acting as an AI assistant executing these instructions, follow each phase thoroughly, generate unified diffs for modified files, and do not make unsolicited modifications outside of these requirements.

---

## Phase 1: Root Directory Tooling & Scripts (`/`)
**Objective**: Standardize the Nix environment, spellchecking, and test cleanup utilities located at the root of the repository.

1.  **Nix Configurations (`flake.nix` & `.envrc`)**:
    *   Update `flake.nix` to logically separate downloaded custom derivations (e.g., `leftovers`, `terraform`) into their own list before appending standard `nixpkgs`.
        ```nix
          devPackages = [
            # place our downloaded packages here
            leftovers
            terraform
          ] ++ (with pkgs; [
            # here are the packages from the nix repository
            actionlint
        ```
    *   Add `terraform` natively as a downloaded derivation in the flake instead of relying on external path resolution.
        ```nix
          terraform-version = {
            "selected" = "1.5.7";
          };
          terraform-prep = {
            "aarch64-darwin" = {
              "url" = "https://releases.hashicorp.com/terraform/${terraform-version.selected}/terraform_${terraform-version.selected}_darwin_arm64.zip";
              "sha" = "sha256-23wz6xpEa3OkQ+LFW1MoRfe3DNVhAL7EyW8Vz6tfUMs=";
              "checksum" = "db7c33eb1a446b73a443e2c55b532845f7b70cd56100bec4c96f15cfab5f50cb";
            };
            "x86_64-linux" = {
              "url" = "https://releases.hashicorp.com/terraform/${terraform-version.selected}/terraform_${terraform-version.selected}_linux_amd64.zip";
              "sha" = "sha256-wO17wy7lKuJVr5mCyMiKekxhBIXPHVX+6wN+q3X6CCw=";
              "checksum" = "c0ed7bc32ee52ae255af9982c8c88a7a4c610485cf1d55feeb037eab75fa082c";
            };
            # linux container running on darwin or arm linux
            "aarch64-linux" = {
              "url" = "https://releases.hashicorp.com/terraform/${terraform-version.selected}/terraform_${terraform-version.selected}_linux_arm64.zip";
              "sha" = "sha256-9LStfGtgiJYKZn40SVyuSQ+wcpR6n/Jmv1kp9TM1ZeQ=";
              "checksum" = "f4b4ad7c6b6088960a667e34495cae490fb072947a9ff266bf5929f5333565e4";
            };
          };
          terraform = pkgs.stdenv.mkDerivation {
            name = "terraform-${terraform-version.selected}";
            src = pkgs.fetchurl {
              url = terraform-prep."${system}".url;
              sha256 = terraform-prep."${system}".sha;
            };
            checksum = terraform-prep."${system}".checksum;
            nativeBuildInputs = [ pkgs.unzip ];
            phases = [ "installPhase" ];
            installPhase = ''
              echo "$checksum  $src" | sha256sum -c -
              install -d $out/bin
              unzip -o $src -d $out/bin
              chmod +x $out/bin/terraform
            '';
          };
        ```
    *   Replace `aspellWithDicts` with `cspell` in the dev shell packages.
    *   Remove `tfswitch` and the creation of homebin
    *   Update `.envrc` syntax to execute `nix profile add` instead of `nix profile install`.

2.  **CSpell Configurations (`cspell.json` & `custom_words.txt`)**:
    *   Create `cspell.json` and a `custom_words.txt` file in the root of the repository containing expected technical terms (e.g., `authconfig`, `kubeconfig`, `nutanix`, `variablize`, `agentic`).
    *   `cspell.json` needs to include exactly this configuration:
        ```
        {
            // Enable your dictionary by adding it to the list of `dictionaries`
            "dictionaries": ["custom-words"],

            // Tell CSpell about your dictionary
            "dictionaryDefinitions": [
                {
                    // The name of the dictionary is used to look it up.
                    "name": "custom-words",
                    // Path to the custom word file. Relative to this `cspell.json` file.
                    "path": "custom_words.txt",
                    // Some editor extensions will use `addWords` for adding words to your
                    // personal dictionary.
                    "addWords": true
                }
            ]
        }
        ```

3.  **Test Execution Scripts (`run_tests.sh` & `cleanup.sh`)**:
    *   Verify `run_tests.sh` executes the cleanup script reliably via `trap 'cleanup.sh $IDENTIFIER' EXIT` (adjusting syntax if necessary).
    *   Update `run_tests.sh` to remove stale `.terraform` directories and `.terraform.lock.hcl` files, and run `terraform init -upgrade` before priming the plugin cache for both the root module and all example modules.
    *   Update the `cleanup.sh` script to explicitly include a new block for safely removing Route 53 records without destroying the hosted zones themselves:
        ```bash
          # remove route 53 records
          echo "Clearing out Route 53 records if they were missed..."
          LOWER_IDENTIFIER=$(echo "$IDENTIFIER" | tr '[:upper:]' '[:lower:]')
          attempts=0
          while [ $attempts -lt $max_attempts ]; do
            while read -r hz; do
              if [ -z "$hz" ]; then
                continue
              fi
              while read -r record; do
                if [ -z "$record" ]; then
                  continue
                fi
                record_name=$(echo "$record" | jq -r '.Name')
                record_type=$(echo "$record" | jq -r '.Type')
                echo "   removing route 53 record $record_name of type $record_type from zone $hz..."
                change_batch=$(jq -n --argjson rec "$record" '{"Changes": [{"Action": "DELETE", "ResourceRecordSet": $rec}]}')
                aws route53 change-resource-record-sets --hosted-zone-id "$hz" --change-batch "$change_batch" > /dev/null 2>&1 || true
              done <<<"$(aws route53 list-resource-record-sets --hosted-zone-id "$hz" | jq -c --arg ID "$LOWER_IDENTIFIER" '.ResourceRecordSets[]? | select(.Name | contains($ID))')"
            done <<<"$(aws route53 list-hosted-zones | jq -r '.HostedZones[]?.Id')"
            sleep $((attempts * 10))
            attempts=$((attempts + 1))
          done
        ```

4.  **ESLint Configuration (`eslint.config.js`)**:
    *   Create `eslint.config.js` in the root of the repository using the modern "Flat Config" format:
        ```javascript
        import js from "@eslint/js";
        import globals from "globals";

        export default [
            js.configs.recommended,
            {
                languageOptions: {
                    ecmaVersion: "latest",
                    sourceType: "module",
                    globals: {
                        ...globals.node
                    }
                }
            }
        ];
        ```
    *   Update `.github/workflows/scripts/eslint.sh` to install dependencies using `npm install --no-save eslint @eslint/js globals` to prevent generating `package.json`/`package-lock.json` files during CI.
    *   Update .gitignore to ignore the node_modules directory, we don't need to commit it.

---

## Phase 2: GitHub Actions & Dependabot (`.github/`)
**Objective**: Standardize GitHub workflows, restrict permissions, externalize script logic, and add dependabot.

1.  **Dependabot Configuration**:
    *   Create or update `.github/dependabot.yaml` to watch the Docker ecosystem for CI Image updates:
        ```yaml
        version: 2
        updates:
          # Check for updates to GitHub Actions every week
          - package-ecosystem: "github-actions"
            directory: "/"
            schedule:
              interval: "weekly"
              day: "sunday" # this way it is ready for review on Monday
            commit-message:
              prefix: "fix"
          # Check for updates to terraform providers every week
          - package-ecosystem: "terraform"
            directory: "/"
            schedule:
              interval: "weekly"
              day: "sunday" # this way it is ready for review on Monday
            commit-message:
              prefix: "fix"
        ```

2.  **Workflow Security & Standardization (`.github/workflows/*.yaml`)**:
    *   Ensure all workflow files have a top-level `permissions: {}` block and job-level strict permissions.
    *   Ensure every step begins with a descriptive `name:`.
        - When adding a name, make sure to remove the dash from the previous begining, otherwise it will be interpreted as a new step
    *   Ensure all jobs have `timeout-minutes` set appropriately, default to '30'
    *   Ensure all jobs use the nix ci-image container.
        ```yaml
          container:
            image: ghcr.io/rancher/ci-image/nix:20260603-18
        ```
    *   Remove all `install-nix` steps.
    *   Pin all external actions to a commit SHA with the version inline in a comment.
        ```yaml
          - name: 'FOSSA Scan'
            # https://github.com/fossas/fossa-action/releases
            uses: fossas/fossa-action@ff70fe9fe17cbd2040648f1c45e8ec4e4884dcf3 # v1.9.0
        ```
    *   Except for the rancher-eio step which should look exactly like this:
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
    *   Terraform fmt steps need to include include `-diff`: `terraform fmt -check -recursive -diff`.

3.  **Script Externalization (`.github/workflows/scripts/`)**:
    *   Create `.github/workflows/scripts/nix-run.sh`:
    ```bash
      #!/usr/bin/env bash
      set -euo pipefail

      if [ -z "${NIX_SSL_CERT_FILE:-}" ]; then
        for cert in /etc/ssl/certs/ca-certificates.crt \
                    /etc/ssl/certs/ca-bundle.crt \
                    /etc/pki/tls/certs/ca-bundle.crt \
                    /etc/ssl/ca-bundle.pem \
                    /var/lib/ca-certificates/ca-bundle.pem; do
          if [ -f "$cert" ]; then
            export NIX_SSL_CERT_FILE="$cert"
            break
          fi
        done
      fi

      export SSL_CERT_FILE="${NIX_SSL_CERT_FILE:-}"
      export CURL_CA_BUNDLE="${NIX_SSL_CERT_FILE:-}"

      printf "%s\n" "$*" > .nix-script.sh
      trap 'rm -f .nix-script.sh' EXIT

      # Ensure the suse user can read/write the script and current directory
      chown -R suse:suse . || true

      sudo -E -u suse /home/suse/.nix-profile/bin/nix develop \
        --ignore-environment \
        --extra-experimental-features nix-command \
        --extra-experimental-features flakes \
        --keep NIX_SSL_CERT_FILE \
        --keep SSL_CERT_FILE \
        --keep CURL_CA_BUNDLE \
        --keep NIX_ENV_LOADED \
        --keep TERM \
        --keep HOME \
        --keep SSH_AUTH_SOCK \
        --keep GITHUB_TOKEN \
        --keep GITHUB_OWNER \
        --keep AWS_ACCESS_KEY_ID \
        --keep AWS_SECRET_ACCESS_KEY \
        --keep AWS_SESSION_TOKEN \
        --keep AWS_ROLE \
        --keep AWS_REGION \
        --keep AWS_DEFAULT_REGION \
        --keep IDENTIFIER \
        --keep ZONE \
        --keep ACME_SERVER_URL \
        --command bash -e .nix-script.sh

    ```
    *   Extract inline `github-script` steps to `.js` files in `scripts/` and import dynamically.
        ```typescript
            const scriptPath = `${process.env.GITHUB_WORKSPACE}/.github/workflows/scripts/pr-e2e-pass.js`;
            const { default: script } = await import(scriptPath);
            context.payload.pull_request = { number: ${{ fromJson(steps.release-please.outputs.pr).number }} };
            await script({ github, context });
        ```
        ```typescript
          export default async ({ github, context }) => {};
        ```
    *   Extract inline bash `run:` logic to `.sh` files in `scripts/` and pipe through `nix-run.sh`.
    *   Add an ESLint job to `pull_request.yaml` to validate the new `.js` scripts.

---

## Phase 3: Terraform Configurations & Modules (`*.tf`)
**Objective**: Standardize validations, ensure robust path resolution, and modernize providers in all Terraform files.

1.  **Modernize Validation Blocks (`main.tf` / deploy modules)**:
    *   Remove legacy `one([local.var, "error_message"])` validation hacks found inside `locals {}` blocks.
    *   Replace those hacks by creating a single `terraform_data` resource at the root of the file called `input_validation`, utilizing `lifecycle { precondition {} }` blocks.
    *   This kind of input validation is only necessary for validating in ways the variables.tf can't
        * such as when an input's validation relies on another input's value
    *   Ensure resources depend on this validation resource.
    *   Validations created this way shouldn't rely on other resources, if one does, let me know.

2.  **Fix Path Resolution**:
    *   Find and remove all `abspath()` function calls throughout the Terraform configurations. Replace them with relative paths (e.g., `path.module`, `path.root`) to prevent cross-machine state breakages.

3.  **Replace Local Provider (`hashicorp/local` -> `rancher/file`)**:
    *   Replace all instances of the `hashicorp/local` provider with `rancher/file` in all `versions.tf` files.
    *   Change `local_file` resources and datasources to `file_local`.
    *   Map attributes from `local_file` to `file_local`:
        * example local_file resource: ```
            resource "local_file" "foo" {
              content  = "foo!"
              filename = "${path.module}/foo.bar"
            }
          ```
        * what file_local should look like: ```
            resource "file_local" "foo" {
              directory = "${path.module}"
              name      = "foo.bar"
              contents  = "foo!"
            }
          ```
        * local_file's "content", "content_base64", and "content_sensitive" becomes file_local's "contents".
        * local_file's filename gets split up 
            * the path becomes file_local's directory
            * the basename becomes file_local's name
        * local_file's file_permission becomes file_local's permissions
            * the default for local_file is 0777 while the default for file_local is 0600
            * make a judgement call on the correct permissions to give
            * default to 0755 if you have no better choice
        * if directories don't exist and need to be created use the file_local_directory resource to manage them
            * don't rely on the auto creation of directories for a file_local resource
        * note: `file_local_directory` expects a single `path` argument, not `directory` and `name`.
        * local_file's "source" attribute is special, let me know if you run into this let me know
            * we will need to make a plan for how to deal with the file's content if this one is used

5.  **Validate Versions**:
    *   Inspect all providers listed in `versions.tf` files
        * remove any unused providers
        * add any providers that are used, but not declared
        * make sure to include dependent external module providers (eg. the terraform-aws-server module imports the terraform-aws-access module, make sure to include dependencies from the terraform-aws-access module such as the acme and tls providers)

---

## Phase 4: Go Testing Suite Overhaul (`./test/tests/` -> `./test/`)
**Objective**: Keep Terratest dependencies up-to-date and restructure the Go test package for maintainability.

1.  **Directory Restructuring (`./test/tests/` to `./test/`)**:
    *   Move the testing suite into a dedicated Go module named `test` located at `./test`.
    *   Edit Go mod and test packages to use `/test` instead of `/test/tests`
    *   Update relative paths in `TerraformDir` options inside test files to reflect the new directory depth (e.g., change `../../../examples/` to `../../examples/`).
    *   Ensure all test files unify their package declaration to `package test` (removing legacy `package tests`).

2.  **Dependency Updates**:
    *   Bump `go.mod` to Go version `1.26.0`.
    *   Run `go get -u ./...` and `go mod tidy` to bump all direct and indirect dependencies.
    *   Update `github.com/aws/aws-sdk-go` to `aws-sdk-go-v2` or eliminate the dependency.
    *   Find and update all deprecated functions.
        * `ssh.SshAgentWithKeyPair(t, keyPair.KeyPair)` to `ssh.SSHAgentWithKeyPair(t, t.Context(), keyPair.KeyPair)`
        * `random.UniqueId()` to `random.UniqueID()`
        * `terraform.InitAndApply(t, terraformOptions)` to `terraform.InitAndApplyContext(t, t.Context(), terraformOptions)`
        * `terraform.DestroyE(t, terraformOptions)` to `terraform.DestroyContextE(t, t.Context(), terraformOptions)`
        * `terraform.InitAndPlan(t, terraformOptions)` to `terraform.InitAndPlanContext(t, t.Context(), terraformOptions)`
        * `terraform.OutputAll(t, terraformOptions)` to `terraform.OutputAllContext(t, t.Context(), terraformOptions)`
        * `map[string]interface{}` to `map[string]any`
        * `git.GetRepoRoot(t)` to `git.GetRepoRootContext(t, t.Context(), "")`
        * `aws.DeleteEC2KeyPair(t, keyPair)` to `aws.DeleteEC2KeyPairContext(t, t.Context(), keyPair)`
        * `aws.CreateAndImportEC2KeyPair(t, region, keyPairName)` to `aws.CreateAndImportEC2KeyPairContext(t, t.Context(), region, keyPairName)`
        * `aws.NewEc2ClientE(t, region)` to `aws.NewEc2ClientContextE(t, t.Context(), region)`
        * `aws.AddTagsToResource(t, region, *result.KeyPairs[0].KeyPairId, map[string]string{"Name": keyPairName, "Owner": owner})` to `aws.AddTagsToResourceContext(t, t.Context(), region, *result.KeyPairs[0].KeyPairId, map[string]string{"Name": keyPairName, "Owner": owner})`
        * `terraform.InitAndApplyE(t, ` to `terraform.InitAndApplyContextE(t, t.Context(), `
        * `terraform.OutputMap(t, ` to `terraform.OutputMapContext(t, t.Context(), `
        * `ssh.CheckSshCommand(t, host` to `ssh.CheckSSHCommandContext(t, t.Context(), &host`
        * `ssh.SshAgent` to `ssh.SSHAgent`
