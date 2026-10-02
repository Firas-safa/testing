#!/usr/bin/env bash
# PostToolUse hook (Bash): after Claude runs `git push`, release your
# FEATURES.md locks for the current branch. release-locks.sh still refuses
# unless everything is committed and pushed, so a teammate who takes a file
# over always merges your pushed work first.

input=$(tr -d '\r\n')

cmd=$(printf '%s' "$input" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(\([^"\\]\|\\.\)*\)".*/\1/p')
printf '%s' "$cmd" | grep -qE '(^|[;&|[:space:]])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+push([[:space:]]|$)' || exit 0

proj=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}
proj=$(printf '%s' "$proj" | sed 's#\\#/#g; s#/$##')
[ -z "$proj" ] && exit 0
. "$proj/.claude/scripts/locks-lib.sh"

load_config
[ -f "$FEATURES_MD" ] && [ -n "$me" ] || exit 0

# Nothing to do unless you hold locks on this branch.
branch=$(current_branch)
grep -qiF "**LOCKED** ($me) on \`$branch\`" "$FEATURES_MD" || exit 0

out=$(bash "$proj/.claude/scripts/release-locks.sh" "$branch" 2>&1)
printf '{"systemMessage":"%s"}\n' "$(printf '%s' "$out" | tr '\n"\\' " '/")"
exit 0
