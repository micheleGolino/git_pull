#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Walk every Git repository below a root folder and run
# `git pull --ff-only` on each local branch that tracks a remote.
# Errors never stop the loop; they are collected for the final report.
# -----------------------------------------------------------------------------

set -euo pipefail   # fail on unset vars and pipe errors, exit on other errors

ROOT_DIR="${1:-$HOME/git}"   # default root is $HOME/git unless given as $1

declare -a SUCCESSFUL_PULLS=()
declare -a FAILED_PULLS=()

pull_repository() {
  local repo_path="$1"

  # Remember the branch that was active when we entered the repo
  local original_branch
  original_branch=$(git -C "$repo_path" rev-parse --abbrev-ref HEAD)

  # Collect all local branches that track a remote (portable: no `mapfile`)
  local branches=()
  while read -r local_branch _; do
    branches+=("$local_branch")
  done < <(
    git -C "$repo_path" for-each-ref \
      --format='%(refname:short) %(upstream:short)' refs/heads |
    awk '$2 != "" {print $1}'
  )

  # Update each tracked branch
  for br in "${branches[@]}"; do
    git -C "$repo_path" checkout -q "$br" || continue
    if git -C "$repo_path" pull --ff-only --quiet; then
      SUCCESSFUL_PULLS+=("${repo_path}:${br}")
    else
      FAILED_PULLS+=("${repo_path}:${br}")
    fi
  done

  # Restore the original branch
  git -C "$repo_path" checkout -q "$original_branch"
}

# Discover every `.git` directory and process the parent folder
while IFS= read -r -d '' git_dir; do
  repo_dir="$(dirname "$git_dir")"
  echo ">> Processing $repo_dir"
  pull_repository "$repo_dir" || true   # never stop on a single failure
done < <(find "$ROOT_DIR" -type d -name ".git" -print0)

# ---------- Final report -----------------------------------------------------
echo
echo "==================== PULL REPORT ===================="
echo "---- FAILED PULLS ----"
((${#FAILED_PULLS[@]})) && printf '%s\n' "${FAILED_PULLS[@]}" || echo "None"

echo
echo "---- SUCCESSFUL PULLS ----"
((${#SUCCESSFUL_PULLS[@]})) && printf '%s\n' "${SUCCESSFUL_PULLS[@]}" || echo "None"
echo "====================================================="
