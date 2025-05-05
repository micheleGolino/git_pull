#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Walk every Git repository below a root folder and run
# `git pull --ff-only` on each local branch that tracks a remote.
# Repositories are processed in parallel (default: 4 at a time).
# Works on macOS (Bash 3.2) and any modern Linux distribution.
# -----------------------------------------------------------------------------

set -euo pipefail   # exit on most errors, fail on unset vars and pipe errors

# -------------------------- Configuration ------------------------------------
ROOT_DIR="${1:-$HOME/git}"   # root folder to scan
MAX_JOBS="${2:-4}"           # maximum concurrent repositories

# Temporary files to collect results (atomic appends are POSIX‑safe)
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/gitpull.XXXXXX")"
SUCCESS_FILE="$TMP_DIR/success.log"
FAIL_FILE="$TMP_DIR/fail.log"
: >"$SUCCESS_FILE"  # truncate / create
: >"$FAIL_FILE"

# -------------------------- Functions ----------------------------------------
pull_repository() {
  local repo_path="$1"

  # Remember current branch
  local original_branch
  original_branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD)

  # Get all local branches that track a remote (portable: no mapfile/readarray)
  local branches=()
  while read -r local_branch _; do
    branches+=("$local_branch")
  done < <(
    git -C "$repo_path" for-each-ref \
      --format='%(refname:short) %(upstream:short)' refs/heads |
    awk '$2 != "" {print $1}'
  )

  # Pull each tracked branch
  for br in "${branches[@]}"; do
    git -C "$repo_path" checkout -q "$br" || {
      echo "${repo_path}:${br}" >>"$FAIL_FILE"
      continue
    }
    if git -C "$repo_path" pull --ff-only --quiet; then
      echo "${repo_path}:${br}" >>"$SUCCESS_FILE"
    else
      echo "${repo_path}:${br}" >>"$FAIL_FILE"
    fi
  done

  # Restore original branch
  git -C "$repo_path" checkout -q "$original_branch"
}

spawn_job() {
  pull_repository "$1" &
}

# -------------------------- Main loop ----------------------------------------
echo "Scanning $ROOT_DIR …"
while IFS= read -r -d '' git_dir; do
  repo_dir="$(dirname "$git_dir")"
  echo ">> Queuing  $repo_dir"
  spawn_job "$repo_dir"

  # Throttle concurrency: wait until running jobs < MAX_JOBS
  while (( $(jobs -p | wc -l | tr -d ' ') >= MAX_JOBS )); do
    sleep 0.5
  done
done < <(find "$ROOT_DIR" -type d -name ".git" -print0)

wait   # wait for all background jobs to finish

# -------------------------- Final report -------------------------------------
echo
echo "==================== PULL REPORT ===================="
echo "---- FAILED PULLS ----"
if [[ -s "$FAIL_FILE" ]]; then
  sort "$FAIL_FILE"
else
  echo "None"
fi

echo
echo "---- SUCCESSFUL PULLS ----"
if [[ -s "$SUCCESS_FILE" ]]; then
  sort "$SUCCESS_FILE"
else
  echo "None"
fi
echo "====================================================="

# Cleanup
rm -rf "$TMP_DIR"