#!/usr/bin/env bash

# pull-ci-logs.sh - Retrieve GitHub CI workflow logs and save to a temporary file.
# Conforms to shell-scripts.instructions.md guidelines.

set -euo pipefail

show_help() {
    cat <<EOF
Usage: pull-ci-logs.sh [run-id] [options]

Downloads workflow logs from a GitHub Actions run to a temporary file.

Arguments:
  run-id                  Optional. The database ID of the run. If omitted,
                          you will be prompted to select from the most recent runs.

Options:
  -r, --repo OWNER/REPO   The GitHub repository (default: rancher/terraform-provider-file)
  -l, --limit LIMIT       Number of recent runs to fetch for selection (default: 10)
  -w, --workflow NAME     Filter runs by workflow name (e.g., "Release", "pull_request", "FOSSA Scanning")
  -s, --status STATUS     Filter runs by status (e.g., "completed", "failure", "success")
  -f, --failed-only       Only fetch logs for failed steps
  -o, --output FILE       The file path to save logs (default: /tmp/gh-run-<run-id>.log)
  -h, --help              Show this help message and exit

Examples:
  # Interactively select a run and download full logs
  $ .agent/skills/pull-ci-logs.sh

  # Interactively select from recently failed "Release" workflow runs
  $ .agent/skills/pull-ci-logs.sh -w Release -s failure

  # Download full logs for a specific run ID
  $ .agent/skills/pull-ci-logs.sh 30394694424

  # Download only failed step logs for a run
  $ .agent/skills/pull-ci-logs.sh 30394694424 --failed-only

  # Download logs from a different repository
  $ .agent/skills/pull-ci-logs.sh -r some-org/some-repo
EOF
}

select_run() {
    local repo="$1"
    local limit="$2"
    local workflow="$3"
    local status="$4"

    local msg="Fetching the $limit most recent runs"
    if [[ -n "$workflow" ]]; then
        msg="$msg for workflow '$workflow'"
    fi
    if [[ -n "$status" ]]; then
        msg="$msg with status '$status'"
    fi
    msg="$msg for $repo..."
    echo "$msg" >&2

    local extra_args=()
    if [[ -n "$workflow" ]]; then
        extra_args+=("-w" "$workflow")
    fi
    if [[ -n "$status" ]]; then
        extra_args+=("-s" "$status")
    fi

    local run_data
    run_data=$(gh run list -R "$repo" --limit "$limit" "${extra_args[@]+"${extra_args[@]}"}" --json databaseId,workflowName,headBranch,displayTitle,status,conclusion 2>/dev/null | jq -r '.[] | "\(.databaseId)\t[\(.status)/\(.conclusion)] \(.workflowName) on \(.headBranch) - \(.displayTitle)"' || true)

    if [[ -z "$run_data" ]]; then
        echo "Error: No recent runs found matching the criteria or unable to access repository '$repo'." >&2
        exit 1
    fi

    # Read lines using mapfile
    local lines=()
    mapfile -t lines <<< "$run_data"

    echo "Select a workflow run to view/download logs:" >&2
    local i
    for i in "${!lines[@]}"; do
        local line="${lines[i]}"
        local desc="${line#*$'\t'}"
        printf "%2d) %s\n" "$((i + 1))" "$desc" >&2
    done

    local selection
    while true; do
        read -rp "Enter number (1-${#lines[@]}) or 'q' to quit: " selection < /dev/tty
        if [[ "$selection" == "q" ]]; then
            echo "Aborted by user." >&2
            exit 0
        fi
        if [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#lines[@]} )); then
            break
        fi
        echo "Invalid selection. Please try again." >&2
    done

    local selected_line="${lines[$((selection - 1))]}"
    local run_id="${selected_line%%$'\t'*}"
    echo "$run_id"
}

main() {
    local repo="rancher/terraform-provider-file"
    local limit="10"
    local failed_only=false
    local output_file=""
    local run_id=""
    local workflow=""
    local status=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -r|--repo)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --repo requires an argument." >&2
                    exit 1
                fi
                repo="$2"
                shift 2
                ;;
            -l|--limit)
                if [[ -z "${2:-}" ]] || ! [[ "$2" =~ ^[0-9]+$ ]]; then
                    echo "Error: --limit requires a numeric argument." >&2
                    exit 1
                fi
                limit="$2"
                shift 2
                ;;
            -w|--workflow)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --workflow requires an argument." >&2
                    exit 1
                fi
                workflow="$2"
                shift 2
                ;;
            -s|--status)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --status requires an argument." >&2
                    exit 1
                fi
                status="$2"
                shift 2
                ;;
            -f|--failed-only)
                failed_only=true
                shift
                ;;
            -o|--output)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --output requires an argument." >&2
                    exit 1
                fi
                output_file="$2"
                shift 2
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                show_help
                exit 1
                ;;
            *)
                if [[ -n "$run_id" ]]; then
                    echo "Error: Only one run-id can be specified." >&2
                    exit 1
                fi
                if ! [[ "$1" =~ ^[0-9]+$ ]]; then
                    echo "Error: Invalid run-id '$1'. Run-id must be a number." >&2
                    exit 1
                fi
                run_id="$1"
                shift
                ;;
        esac
    done

    # Ensure gh CLI is installed
    if ! command -v gh &>/dev/null; then
        echo "Error: The GitHub CLI (gh) is not installed or not in PATH." >&2
        exit 1
    fi

    # Ensure jq is installed
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is required but not installed or not in PATH." >&2
        exit 1
    fi

    if [[ -z "$run_id" ]]; then
        run_id=$(select_run "$repo" "$limit" "$workflow" "$status")
    fi

    if [[ -z "$output_file" ]]; then
        output_file="/tmp/gh-run-${run_id}.log"
    fi

    # Create the parent directory for output if it doesn't exist
    mkdir -p "$(dirname "$output_file")"

    echo "Downloading logs for run $run_id from $repo..."
    local view_flags=()
    if [[ "$failed_only" == "true" ]]; then
        view_flags+=("--log-failed")
    else
        view_flags+=("--log")
    fi

    # Retrieve logs and write to file
    if ! gh run view "$run_id" -R "$repo" "${view_flags[@]}" > "$output_file"; then
        echo "Error: Failed to fetch logs for run $run_id." >&2
        exit 1
    fi

    echo "Logs successfully written to: $output_file"
    echo "You can view them using: less -R \"$output_file\" or code \"$output_file\""
}

main "$@"
