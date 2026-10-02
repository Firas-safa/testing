#!/usr/bin/env bash
# Usage:
#   lock-files.sh --check <file>...          report conflicts, change nothing
#   lock-files.sh <feature-slug> <file>...   lock the files for a planned feature
#
# Locking is all-or-nothing: if any file is locked by someone else, nothing is
# written. Files a teammate RELEASED are merged in from their pushed branch
# first. Must run on the feature's branch (feature/<slug>), not on main.

proj=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not inside the git repo."; exit 1; }
. "$proj/.claude/scripts/locks-lib.sh"
load_config
[ -f "$FEATURES_MD" ] || { echo "FEATURES.md not found. Set FEATURES_MD in .claude/settings.local.json."; exit 1; }
[ -n "$me" ] || { echo "Set FEATURES_USER in .claude/settings.local.json."; exit 1; }

check_only="" slug=""
if [ "$1" = "--check" ]; then check_only=1; shift; else slug=$1; shift; fi
[ $# -gt 0 ] || { echo "Usage: lock-files.sh [--check | <feature-slug>] <file>..."; exit 1; }

conflicts="" coordinate="" mine="" free="" released="" released_branches=""
for f in "$@"; do
  rel=$(rel_path "$f")
  match=$(find_lock "$rel")
  text=${match#*:}
  owner=$(lock_owner "$text")
  case "$(lock_kind "$text")" in
    "") free="$free $rel" ;;
    COORDINATE) coordinate="$coordinate $rel" ;;
    LOCKED)
      if [ "$(lc "$owner")" = "$(lc "$me")" ]; then
        mine="$mine $rel"
      else
        conflicts="$conflicts
  $rel  ← LOCKED by $owner on $(lock_branch "$text")"
      fi ;;
    RELEASED)
      released="$released $rel"
      [ "$(lc "$owner")" != "$(lc "$me")" ] &&
        released_branches="$released_branches $owner:$(lock_branch "$text")" ;;
  esac
done

if [ -n "$conflicts" ]; then
  echo "CONFLICT - these files are locked by someone else:$conflicts"
  echo "Nothing was locked. Wait for them to /release-locks, coordinate with them, or change the plan."
  exit 1
fi
[ -n "$coordinate" ] && echo "COORDINATE (shared, not locked - Claude will ask before each edit):$coordinate"

if [ -n "$check_only" ]; then
  echo "OK - no conflicts."
  [ -n "$free" ] && echo "Free, will be locked:$free"
  [ -n "$released" ] && echo "Released by a teammate, their pushed branch will be merged first:$released"
  [ -n "$mine" ] && echo "Already locked by you:$mine"
  exit 0
fi

branch=$(current_branch)
case "$branch" in
  main | master | HEAD) echo "You are on $branch. Create the feature branch first: git switch -c feature/$slug"; exit 1 ;;
esac

# Merge each teammate branch we are taking files from (stop on first failure).
for ob in $(printf '%s\n' $released_branches | sort -u); do
  merge_released "${ob%%:*}" "${ob#*:}" || { echo "$ERR"; echo "Nothing was locked."; exit 1; }
  [ -n "$MERGE_MSG" ] && echo "$MERGE_MSG"
done

has_section "$slug" || add_section "$slug" "$branch"
for rel in $free $released; do
  match=$(find_lock "$rel")
  [ -n "$match" ] && delete_line "${match%%:*}"
  add_lock "$slug" "$(lock_line "$rel" "$branch" "planned $(now)")"
done

echo "Locked for $me under feature '$slug' (branch $branch):"
printf '  %s\n' $free $released
[ -n "$mine" ] && echo "Already yours:$mine"
exit 0
