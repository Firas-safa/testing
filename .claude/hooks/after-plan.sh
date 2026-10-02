#!/usr/bin/env bash
# PostToolUse hook (ExitPlanMode): once a plan is approved, tell Claude to
# lock the plan's files in FEATURES.md before editing anything.
cat >/dev/null
cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"The plan was approved. Before editing ANY file, lock every file the plan will create or modify: (1) if on main, run git switch main && git pull, then git switch -c feature/<feature-slug>; (2) run: bash .claude/scripts/lock-files.sh <feature-slug> <file1> <file2> ... (project-relative paths). If it reports CONFLICT, stop and tell the user who holds the lock - do not edit those files. (3) Create features/<feature-slug>/status.md, discoveries.md and blockers.md next to FEATURES.md if they do not exist."}}
EOF
