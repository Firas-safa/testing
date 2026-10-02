# Shared helpers for the FEATURES.md lock scripts. Source this file after
# setting $proj (the project root, forward slashes).
#
# Lock line format in FEATURES.md (one file per line):
#   - `path` ← **LOCKED** (Name) on `branch` — note
#   - `path` ← **RELEASED** (Name) from `branch` — note
#   - `path` ← **COORDINATE** — note
# A feature section is marked with  <!-- feature: slug -->  and holds its
# locks under a "#### Files Being Touched" heading.

lc() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
git_() { git -C "$proj" "$@"; }
now() { date '+%Y-%m-%d %H:%M'; }

# FEATURES_MD / FEATURES_USER come from the env, else settings.local.json.
load_config() {
  local f="$proj/.claude/settings.local.json"
  setting() { sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$f" 2>/dev/null; }
  FEATURES_MD=${FEATURES_MD:-$(setting FEATURES_MD)}
  me=${FEATURES_USER:-$(setting FEATURES_USER)}
}

current_branch() { git_ rev-parse --abbrev-ref HEAD 2>/dev/null; }

# feature/wishlist → wishlist
slug_of_branch() { case "$1" in feature/*) printf '%s' "${1#feature/}" ;; esac; }

# Normalize a path given by the user/Claude to project-relative form.
rel_path() {
  local p
  p=$(printf '%s' "$1" | sed 's#\\#/#g; s#^\./##')
  case "$(lc "$p")" in
    "$(lc "$proj")"/*) p=${p:${#proj}+1} ;;
  esac
  printf '%s' "$p"
}

# find_lock <rel> → "lineno:text" of the lock line for that file, or nothing.
find_lock() {
  grep -nE '\*\*(LOCKED|COORDINATE|RELEASED)\*\*' "$FEATURES_MD" | tr -d '\r' |
    while IFS= read -r l; do
      p=$(printf '%s' "${l#*:}" | sed -n 's/^[^`]*`\([^`]*\)`.*/\1/p')
      if [ -n "$p" ] && [ "$(lc "$p")" = "$(lc "$1")" ]; then
        printf '%s\n' "$l"
        break
      fi
    done
}
lock_kind() { printf '%s' "$1" | sed -n 's/.*\*\*\(LOCKED\|COORDINATE\|RELEASED\)\*\*.*/\1/p'; }
lock_owner() { printf '%s' "$1" | sed -n 's/.*\*\*\(LOCKED\|RELEASED\)\*\*[^(]*(\([^)]*\)).*/\2/p'; }
lock_branch() { printf '%s' "$1" | sed -n 's/.*\*\*\(LOCKED\|RELEASED\)\*\*[^`]* \(on\|from\) `\([^`]*\)`.*/\3/p'; }

lock_line() { printf -- '- `%s` ← **LOCKED** (%s) on `%s` — %s' "$1" "$me" "$2" "$3"; }

# Rewrite FEATURES.md in place (keeps the same file for OneDrive).
_write() { cat "$1" >"$FEATURES_MD" && rm -f "$1"; }

replace_line() { # <lineno> <text>
  local tmp; tmp=$(mktemp)
  T=$2 awk -v n="$1" 'NR == n { print ENVIRON["T"]; next } { print }' "$FEATURES_MD" >"$tmp" && _write "$tmp"
}

delete_line() { # <lineno>
  local tmp; tmp=$(mktemp)
  awk -v n="$1" 'NR != n' "$FEATURES_MD" >"$tmp" && _write "$tmp"
}

has_section() { grep -q "<!-- feature: $1 -->" "$FEATURES_MD"; }

# Create the feature section at the top of "Current Features in Progress".
add_section() { # <slug> <branch>
  local tmp title
  title=$(printf '%s' "$1" | sed 's/[-_]/ /g; s/\b\(.\)/\u\1/g')
  tmp=$(mktemp)
  S="### $title
<!-- feature: $1 -->
- **Status**: 🟡 IN PROGRESS
- **Owner**: $me
- **Branch**: \`$2\`
- **Started**: $(date '+%Y-%m-%d')
- **Knowledge base**: \`features/$1/\`

#### Files Being Touched
" awk '
    { print }
    /^## Current Features in Progress/ && !done { print ""; print ENVIRON["S"]; done = 1 }
    END { if (!done) { print ""; print "## Current Features in Progress"; print ""; print ENVIRON["S"] } }
  ' "$FEATURES_MD" >"$tmp" && _write "$tmp"
}

# Add a lock line to the feature's section, or to "Auto-claimed Locks" when
# there is no section for it.
add_lock() { # <slug> <text>
  local tmp; tmp=$(mktemp)
  if [ -n "$1" ] && has_section "$1"; then
    T=$2 M="<!-- feature: $1 -->" awk '
      { print }
      index($0, ENVIRON["M"]) { in_s = 1 }
      in_s && !done && /^#### Files Being Touched/ { print ENVIRON["T"]; done = 1 }
    ' "$FEATURES_MD" >"$tmp" && _write "$tmp"
  elif grep -q '^## Auto-claimed Locks' "$FEATURES_MD"; then
    T=$2 awk '{ print } /^## Auto-claimed Locks/ { print ""; print ENVIRON["T"]; getline; if ($0 != "") print }' \
      "$FEATURES_MD" >"$tmp" && _write "$tmp"
  else
    { cat "$FEATURES_MD"; printf '\n## Auto-claimed Locks\n\n%s\n' "$2"; } >"$tmp" && _write "$tmp"
  fi
}

# Bring a teammate's released, pushed branch into the current branch.
# Sets MERGE_MSG on success; sets ERR and returns 1 on failure (nothing changed).
merge_released() { # <owner> <branch>
  local out b=$2
  MERGE_MSG="" ERR=""
  [ "$b" = "$(current_branch)" ] && return 0
  case "$(current_branch)" in
    main | master)
      ERR="You are on $(current_branch). Switch to your own feature branch first (git switch -c feature/<name>)."
      return 1 ;;
  esac
  if ! out=$(git_ fetch -q origin "$b" 2>&1); then
    git_ ls-remote --exit-code origin "refs/heads/$b" >/dev/null 2>&1
    if [ $? -eq 2 ]; then
      MERGE_MSG="Branch $b no longer exists on GitHub (probably merged into main) - pull main to be up to date. "
      return 0
    fi
    ERR="Could not fetch $1's branch $b. Check your connection. Git said: $out"
    return 1
  fi
  git_ merge-base --is-ancestor "origin/$b" HEAD && return 0
  if ! out=$(git_ merge --no-edit "origin/$b" 2>&1); then
    git_ merge --abort >/dev/null 2>&1
    ERR="Could not auto-merge $1's branch $b (nothing was changed). Commit your own changes, then run: git merge origin/$b and resolve conflicts. Git said: $out"
    return 1
  fi
  MERGE_MSG="Merged $1's pushed branch $b. "
}
