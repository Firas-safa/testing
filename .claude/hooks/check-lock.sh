#!/usr/bin/env bash
# PreToolUse hook: stops Claude from editing files that FEATURES.md locks for
# another developer.
#
# FEATURES.md line formats it understands:
#   - `lib/models/product.dart` ← **LOCKED** (Firas)   → only Firas may edit
#   - `lib/main.dart` ← **COORDINATE** ...              → ask before editing
#
# Per-developer config (in .claude/settings.local.json → "env"):
#   FEATURES_MD    full path to the shared FEATURES.md
#   FEATURES_USER  your name as written in FEATURES.md (default: first word
#                  of `git config user.name`)

input=$(tr -d '\r\n')

# File being edited (Edit/Write use file_path, NotebookEdit uses notebook_path).
file=$(printf '%s' "$input" |
  sed -n 's/.*"\(file_path\|notebook_path\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p' |
  sed 's#\\\\#/#g; s#\\#/#g')
[ -z "$file" ] && exit 0

if [ -z "$FEATURES_MD" ] || [ ! -f "$FEATURES_MD" ]; then
  echo '{"systemMessage":"Lock check skipped: FEATURES_MD is not set or the file was not found. See .claude/settings.local.json."}'
  exit 0
fi

me=${FEATURES_USER:-$(git config user.name 2>/dev/null | awk '{print $1}')}
me_lc=$(printf '%s' "$me" | tr '[:upper:]' '[:lower:]')
file_lc=$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')

while IFS= read -r line; do
  locked=$(printf '%s' "$line" | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p')
  [ -z "$locked" ] && continue
  locked_lc=$(printf '%s' "$locked" | tr '[:upper:]' '[:lower:]')
  case "$file_lc" in
    */"$locked_lc" | "$locked_lc") ;;
    *) continue ;;
  esac

  if printf '%s' "$line" | grep -q '\*\*LOCKED\*\*'; then
    owner=$(printf '%s' "$line" | sed -n 's/.*\*\*LOCKED\*\*[^(]*(\([^)]*\)).*/\1/p')
    owner_lc=$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]')
    [ -n "$me_lc" ] && [ "$owner_lc" = "$me_lc" ] && exit 0
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s is LOCKED by %s in FEATURES.md (you are %s). Do not edit it. Ask %s first, or wait until the feature is merged and the lock is removed."}}\n' \
      "$locked" "$owner" "${me:-unknown}" "$owner"
    exit 0
  fi

  if printf '%s' "$line" | grep -q '\*\*COORDINATE\*\*'; then
    printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s is marked COORDINATE in FEATURES.md. Check with the team before changing it."}}\n' \
      "$locked"
    exit 0
  fi
done < <(grep -E '\*\*(LOCKED|COORDINATE)\*\*' "$FEATURES_MD")

exit 0
