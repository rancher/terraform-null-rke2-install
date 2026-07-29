# Temporary Checklist: Test Suite Variable Refactoring and Centralized Test Data Path

Track progress of implementation steps.

## Phase 1: Test Utils Refactoring
- [x] Implement `hasVariableDeclared` in `test/util.go`
- [x] Update `Setup` in `test/util.go` to dynamically inject variables
- [x] Update `Teardown` signature and body to accept `id` and remove `test/data/${id}`
- [x] Add `test/data` to `.gitignore`

## Phase 2: Example Interface Standardisation
- [x] Declare `local_file_path` variable in each example's `variables.tf`
- [x] Condition `local_file_path` local value on `var.local_file_path` in each example's `main.tf`

## Phase 2b: Example External Module Upgrades
- [x] Upgrade `rancher/access/aws` to `v4.0.6` in all relevant examples
- [x] Upgrade `rancher/server/aws` to `v2.0.4` in all relevant examples
- [x] Upgrade `rancher/rke2-download/github` to `v1.0.3` in all relevant examples
- [x] Upgrade `rancher/rke2-config/local` to `v1.0.4` in all relevant examples

## Phase 3: Test Files Refactoring
- [x] Update all `defer util.Teardown` calls in test packages to pass `id`
- [x] Remove manual `delete(terraformOptions.Vars, "key_name")` in test files

## Phase 4: Validation & Quality Control
- [x] Format Go code using `gofmt`
- [x] Check Go test compilation using `go test -c ./...`
- [x] Validate Terraform examples using `tflint --recursive`
