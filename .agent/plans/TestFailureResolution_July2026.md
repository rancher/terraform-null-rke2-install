# Resolution Plan: Test Failure Resolution (July 2026)

* **Date Proposed**: July 28, 2026
* **Status**: July 28, 2026 (executed)
* **Author**: Gemini CLI

---

## 1. Triage Summary & Root Cause Analysis

### Failed Test: `TestBasic`
* **Log Entry**: 
  ```
  Error: Error creating file: 
    with module.download.file_local.download_dir_readme,
    on .terraform/modules/download/main.tf line 45, in resource "file_local" "download_dir_readme":
    45: resource "file_local" "download_dir_readme" {

  open /Users/matt.trachier/terraform/github.com/rancher/terraform-null-rke2-install/test/data/YS0yMjA1NS1kCg-basic/README.md:
  no such file or directory
  ```
* **Root Cause**:
  The example module upgraded `rancher/rke2-download/github` to `v1.0.3`, which migrated from the legacy `local_file` resource to the modern `file_local` resource of the `rancher/file` provider. Unlike `local_file`, `file_local` does **not** automatically create parent directories. Since `Setup` in `test/util.go` only ensures that `test/data` exists, but does not pre-create the test-specific folder `test/data/${id}`, `file_local` failed when attempting to write `README.md` to a non-existent parent directory.

---

## 2. Proposed Resolution Strategy

### A. Pre-create Test-Specific Data Directory in Setup
We will update `test/util.go`'s `Setup` function to pre-create the full path to `test/data/${id}` on disk before starting Terraform:
```go
	// Ensure the full test/data/${id} directory exists
	errMkdir := os.MkdirAll(filepath.Join(repoRoot, "test", "data", id), 0755)
	require.NoError(t, errMkdir)
```
This guarantees that the directory exists for any resource or provider (such as `file_local`) that expects the target local directory to be already created.

---

## 3. Scope of Affected Files
* **`test/util.go`**: Update `os.MkdirAll` call inside `Setup` to create `filepath.Join(repoRoot, "test", "data", id)` instead of just `filepath.Join(repoRoot, "test", "data")`.

---

## 4. Verification & Validation Plan
* Re-run `TestBasic` using the `run-tests` skill to confirm it initializes, plans, and deploys without encountering directory creation errors.
