#!/usr/bin/env bash
# Usage: release-locks.sh [feature-slug | branch]      (default: current branch)
#
# Marks your FEATURES.md locks for that branch as RELEASED so teammates can
# edit those files. Refuses unless everything is committed and pushed, because
# a teammate's Claude merges origin/<branch> before editing a released file.

proj=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not inside the git repo."; exit 1; }
cd "$proj" || exit 1
. "$proj/.claude/scripts/locks-lib.sh"
load_config
[ -f "$FEATURES_MD" ] || { echo "FEATURES.md not found. Set FEATURES_MD in .claude/settings.local.json."; exit 1; }
[ -n "$me" ] || { echo "Set FEATURES_USER in .claude/settings.local.json."; exit 1; }

branch=${1:-$(current_branch)}
case "$branch" in */*) ;; *) branch="feature/$branch" ;; esac
slug=$(slug_of_branch "$branch")

if [ "$branch" = "$(current_branch)" ] &&
  [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "Refusing: you have uncommitted changes. Commit and push them first:"
  git status --short --untracked-files=no
  exit 1
fi
if ! git fetch -q origin "$branch" 2>/dev/null; then
  echo "Refusing: $branch is not on GitHub yet. Run: git push -u origin $branch"
  exit 1
fi
if ! git merge-base --is-ancestor "$branch" "origin/$branch"; then
  echo "Refusing: $branch has commits that are not pushed. Run: git push"
  exit 1
fi

pattern="\*\*LOCKED\*\* ($me) on \`$branch\`"
files=$(grep -i "$pattern" "$FEATURES_MD" | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p')
if [ -z "$files" ]; then
  echo "No locks held by $me on $branch in FEATURES.md."
  exit 0
fi

stamp=$(now)
tmp=$(mktemp)
sed "\\#$pattern#I{
  s#\*\*LOCKED\*\* (\([^)]*\)) on \`$branch\`#**RELEASED** (\1) from \`$branch\`#I
  s#[[:space:]]*\r\{0,1\}\$# — released $stamp#
}" "$FEATURES_MD" >"$tmp" && _write "$tmp"

# Mark the feature section's status too.
if [ -n "$slug" ] && has_section "$slug"; then
  tmp=$(mktemp)
  T="- **Status**: 🔓 RELEASED — pushed to \`$branch\`, $stamp" M="<!-- feature: $slug -->" awk '
    index($0, ENVIRON["M"]) { in_s = 1 }
    in_s && !done && /^- \*\*Status\*\*:/ { print ENVIRON["T"]; done = 1; next }
    { print }
  ' "$FEATURES_MD" >"$tmp" && _write "$tmp"
fi

echo "Released for others (pushed to origin/$branch):"
printf '  %s\n' $files
echo "When a teammate's Claude first touches one of these, it merges origin/$branch automatically, then locks the file for them."
