#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|NotebookEdit): enforces the locks in FEATURES.md.
#
#   LOCKED (Name)      only Name may edit it
#   COORDINATE         ask before editing
#   RELEASED (Name)    free again: Name's pushed branch is merged in first,
#                      then the file is locked for the editor
#   not listed         free: locked for the editor ("added during work");
#                      planned files are locked up front by lock-files.sh
#
# Per-developer config: FEATURES_MD / FEATURES_USER in .claude/settings.local.json.

input=$(tr -d '\r\n')

clean() { printf '%s' "$1" | tr '\n"\\' " '/"; }
decide() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"%s","permissionDecisionReason":"%s"}}\n' "$1" "$(clean "$2")"
  exit 0
}
note() {
  printf '{"systemMessage":"%s"}\n' "$(clean "$1")"
  exit 0
}

file=$(printf '%s' "$input" |
  sed -n 's/.*"\(file_path\|notebook_path\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p' |
  sed 's#\\\\#/#g; s#\\#/#g')
[ -z "$file" ] && exit 0

proj=${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}
proj=$(printf '%s' "$proj" | sed 's#\\#/#g; s#/$##')
[ -z "$proj" ] && exit 0
. "$proj/.claude/scripts/locks-lib.sh"

case "$(lc "$file")" in
  "$(lc "$proj")"/*) rel=${file:${#proj}+1} ;;
  *) exit 0 ;; # outside the project (e.g. FEATURES.md itself)
esac

load_config
[ -f "$FEATURES_MD" ] || note "Lock check skipped: FEATURES_MD is not set or the file was not found. See .claude/settings.local.json."
[ -n "$me" ] || note "Lock check skipped: FEATURES_USER is not set in .claude/settings.local.json."

branch=$(current_branch)
slug=$(slug_of_branch "$branch")
match=$(find_lock "$rel")

if [ -z "$match" ]; then
  case "$rel" in
    test/* | .claude/* | pubspec.lock) exit 0 ;; # shared, never locked
  esac
  add_lock "$slug" "$(lock_line "$rel" "$branch" "added during work $(now)")"
  note "$rel was not in your plan: locked it for $me in FEATURES.md${slug:+ under feature $slug}."
fi

lineno=${match%%:*}
text=${match#*:}
owner=$(lock_owner "$text")

case "$(lock_kind "$text")" in
  COORDINATE)
    decide ask "$rel is marked COORDINATE in FEATURES.md. Check with the team before changing it."
    ;;
  LOCKED)
    [ "$(lc "$owner")" = "$(lc "$me")" ] && exit 0
    decide deny "$rel is LOCKED by $owner in FEATURES.md (you are $me). Do not edit it. Ask $owner to release it (/release-locks) first."
    ;;
  RELEASED)
    if [ "$(lc "$owner")" != "$(lc "$me")" ]; then
      merge_released "$owner" "$(lock_branch "$text")" ||
        decide deny "$rel was released by $owner, but: $ERR"
    fi
    if [ -n "$slug" ] && has_section "$slug"; then
      # Move it into the editor's feature section.
      delete_line "$lineno"
      add_lock "$slug" "$(lock_line "$rel" "$branch" "added during work $(now)")"
    else
      replace_line "$lineno" "$(lock_line "$rel" "$branch" "added during work $(now)")"
    fi
    note "${MERGE_MSG}Locked $rel for $me in FEATURES.md (was released by $owner)."
    ;;
esac

exit 0
