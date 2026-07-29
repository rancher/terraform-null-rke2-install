# Plan: Test Suite Variable Refactoring and Centralized Test Data Path

* **Date Proposed**: July 28, 2026
* **Status**: July 28, 2026 (executed)
* **Author**: Gemini CLI

---

## 1. Purpose & Context
The current integration and acceptance testing suite has two primary architectural limitations:
1. **Inflexible Variable Injection**: The `Setup` function in `test/util.go` unconditionally sets `key_name`, `key`, and `identifier` variables on Terratest options. However, not all examples accept these variables (e.g., `basic`, `byob`, and `manifest` lack `key_name` variable declaration), causing either Terraform warnings or errors, which require manual test-side hacks (like `delete(terraformOptions.Vars, "key_name")`).
2. **Scattered and Uncleaned Test Artifacts**: Examples are hardcoded to write their state, `kubeconfig`, and credentials to `"${path.root}/data/${local.identifier}"`. Because `${path.root}` resolves to the specific example folder (e.g. `examples/basic`), these files are scattered throughout the codebase. Furthermore, the `test/data` directory is unused, and generated folders are not cleaned up in `Teardown`.

---

## 2. Architectural Design & Proposed Solution

### A. Dynamic Setup Variables
We will make `test/util.go`'s `Setup` smart by inspecting the target example directory's `*.tf` files prior to injecting variables.
* A helper function `hasVariableDeclared(t, directory, varName)` will look for `variable "varName"` inside the `.tf` files of the example directory.
* `Setup` will only inject `key_name`, `key`, `identifier`, and `local_file_path` if they are explicitly declared as input variables. This eliminates the need for test-level workarounds and prevents all undeclared variable warnings/errors.

### B. Centralized test/data Directory
We will expose `local_file_path` as a variable in all examples except `byob` to enable standard standalone execution while allowing tests to override it:
* Update all relevant `examples/*/variables.tf` to declare:
  ```hcl
  variable "local_file_path" {
    type        = string
    description = "The local path to store RKE2 artifacts"
    default     = ""
  }
  ```
* Update `examples/*/main.tf` to dynamically fall back to the default path if not overridden:
  ```hcl
  local_file_path = (var.local_file_path != "" ? var.local_file_path : "${path.root}/data/${local.identifier}")
  ```
* In `test/util.go`, when `local_file_path` is declared as an input, Setup will assign:
  ```go
  terraformVars["local_file_path"] = filepath.Join(repoRoot, "test", "data", id)
  ```
* Update `.gitignore` to ignore `test/data`.

### C. Upgrade External Terraform Modules in Examples
All Rancher-provided external Terraform modules referenced in the examples will be upgraded to their latest stable releases to ensure compatibility and leverage security/bug fixes:
* `rancher/access/aws`: Upgrade from `v4.0.2` to `v4.0.6`
* `rancher/server/aws`: Upgrade from `v2.0.1` to `v2.0.4`
* `rancher/rke2-download/github`: Upgrade from `v1.0.1` to `v1.0.3`
* `rancher/rke2-config/local`: Upgrade from `v1.0.1` to `v1.0.4`

### D. Automatic Cleanup on Teardown
* Update `Teardown` in `test/util.go` to accept the `id` argument:
  ```go
  func Teardown(t *testing.T, directory string, id string, keyPair *aws.Ec2Keypair)
  ```
* Inside `Teardown`, delete `test/data/${id}` using `os.RemoveAll`.
* Update all test packages in `test/` to pass `id` into their `defer util.Teardown` calls.

---

## 3. Scope of Affected Files (27 Files)
* **Testing Infrastructure (2 Files)**:
  - `test/util.go` (Setup / Teardown refactoring, add dynamic checker helper)
  - `.gitignore` (Add `test/data`)
* **Go Test Files (9 Files)**:
  - `test/basic/basic_test.go`
  - `test/byob/byob_test.go`
  - `test/cis/cis_test.go`
  - `test/latest/latest_test.go`
  - `test/manifest/manifest_test.go`
  - `test/nostart/nostart_test.go`
  - `test/reboot/reboot_test.go`
  - `test/stable/stable_test.go`
  - `test/upgrade/upgrade_test.go`
* **Terraform Examples Variables (8 Files)**:
  - `examples/basic/variables.tf`
  - `examples/cis/variables.tf`
  - `examples/latest/variables.tf`
  - `examples/manifest/variables.tf`
  - `examples/nostart/variables.tf`
  - `examples/reboot/variables.tf`
  - `examples/stable/variables.tf`
  - `examples/upgrade/variables.tf`
* **Terraform Examples Main (8 Files)**:
  - `examples/basic/main.tf`
  - `examples/cis/main.tf`
  - `examples/latest/main.tf`
  - `examples/manifest/main.tf`
  - `examples/nostart/main.tf`
  - `examples/reboot/main.tf`
  - `examples/stable/main.tf`
  - `examples/upgrade/main.tf`

---

## 4. Implementation Checklist

### Phase 1: Test Utils Refactoring
- [ ] Implement `hasVariableDeclared` in `test/util.go`
- [ ] Update `Setup` in `test/util.go` to dynamically inject variables
- [ ] Update `Teardown` signature and body to accept `id` and remove `test/data/${id}`
- [ ] Add `test/data` to `.gitignore`

### Phase 2: Example Interface Standardisation
- [ ] Declare `local_file_path` variable in each example's `variables.tf`
- [ ] Condition `local_file_path` local value on `var.local_file_path` in each example's `main.tf`

### Phase 2b: Example External Module Upgrades
- [ ] Upgrade `rancher/access/aws` to `v4.0.6` in all relevant examples
- [ ] Upgrade `rancher/server/aws` to `v2.0.4` in all relevant examples
- [ ] Upgrade `rancher/rke2-download/github` to `v1.0.3` in all relevant examples
- [ ] Upgrade `rancher/rke2-config/local` to `v1.0.4` in all relevant examples

### Phase 3: Test Files Refactoring
- [ ] Update all `defer util.Teardown` calls in test packages to pass `id`
- [ ] Remove manual `delete(terraformOptions.Vars, "key_name")` in test files

### Phase 4: Validation & Quality Control
- [ ] Format Go code using `gofmt`
- [ ] Check Go test compilation using `go test -c ./...`
- [ ] Validate Terraform examples using `tflint --recursive`
