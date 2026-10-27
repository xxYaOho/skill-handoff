#!/bin/sh
# handoff-init.sh — resolve the workspace root and initialise the handoff layout.
#
# Output (stdout, one KEY=VALUE per line):
#   WORKSPACE_ROOT=<abs path>  resolved workspace root
#   HANDOFF_FILE=<abs path>    the HANDOFF.md index
#   HANDOFF_DIR=<abs path>     directory holding handoff documents
#   IS_WORKTREE=true|false     current workspace is a linked git worktree
#   LINKED=true|false          HANDOFF_DIR is a symlink to the main worktree
#   CREATED_INDEX=true|false   HANDOFF.md was created by this run
#   INDEX_VERSION=<x.y|none>   handoff-version from frontmatter (after upgrade)
#   PROTOCOL_VERSION=<x.y>     skill protocol version this script ships
#   UPGRADED=true|false        blockquote/frontmatter refreshed this run
#
# Diagnostics go to stderr. Exit code is non-zero on failure.
#
# Workspace root resolution order:
#   1. $HANDOFF_ROOT                  explicit override
#   2. git rev-parse --show-toplevel  the current worktree's own root
#   3. nearest ancestor with a project marker
#   4. $PWD                           last resort, reported as a warning

set -eu

die()  { printf 'handoff-init: %s\n' "$1" >&2; exit 1; }
warn() { printf 'handoff-init: %s\n' "$1" >&2; }

abspath() { (cd "$1" 2>/dev/null && pwd -P); }

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PROTOCOL_VERSION=$(tr -d ' \t\r\n' < "$SCRIPT_DIR/PROTOCOL_VERSION")
TEMPLATE="$SCRIPT_DIR/templates/blockquote.md"
[ -n "$PROTOCOL_VERSION" ] || die "PROTOCOL_VERSION is empty"
[ -f "$TEMPLATE" ] || die "missing blockquote template"

find_marker_root() {
  dir=$(pwd)
  while [ "$dir" != "/" ]; do
    for marker in package.json pyproject.toml go.mod Cargo.toml deno.json AGENTS.md .git; do
      if [ -e "$dir/$marker" ]; then
        printf '%s' "$dir"
        return 0
      fi
    done
    dir=$(dirname "$dir")
  done
  return 1
}

# --- 1. resolve the workspace root ----------------------------------------
if [ -n "${HANDOFF_ROOT:-}" ]; then
  WORKSPACE_ROOT=$(abspath "$HANDOFF_ROOT") \
    || die "HANDOFF_ROOT is not a directory: $HANDOFF_ROOT"
elif WORKSPACE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) && [ -n "$WORKSPACE_ROOT" ]; then
  :
elif WORKSPACE_ROOT=$(find_marker_root); then
  :
else
  WORKSPACE_ROOT=$(pwd)
  warn "no git repository or project marker found; falling back to \$PWD"
fi

case "$WORKSPACE_ROOT" in
  '' | '/') die "refusing to operate on '$WORKSPACE_ROOT'" ;;
esac
if [ -n "${HOME:-}" ] && [ "$WORKSPACE_ROOT" = "$HOME" ]; then
  die "refusing to operate on the home directory"
fi

HANDOFF_FILE="$WORKSPACE_ROOT/HANDOFF.md"
HANDOFF_DIR="$WORKSPACE_ROOT/.tmp/handoff"

# --- 2. detect a linked worktree (must run before any mkdir) --------------
IS_WORKTREE=false
LINKED=false
GIT_DIR=$(git rev-parse --absolute-git-dir 2>/dev/null || true)
COMMON_DIR=$(git rev-parse --git-common-dir 2>/dev/null || true)
if [ -n "$GIT_DIR" ]; then
  GIT_DIR=$(abspath "$GIT_DIR" || printf '')
fi
if [ -n "$COMMON_DIR" ]; then
  COMMON_DIR=$(abspath "$COMMON_DIR" || printf '')
fi
if [ -n "$GIT_DIR" ] && [ -n "$COMMON_DIR" ] && [ "$GIT_DIR" != "$COMMON_DIR" ]; then
  IS_WORKTREE=true
fi

# --- 3. create the handoff directory, or link it to the main worktree -----
if [ ! -e "$HANDOFF_DIR" ] && [ "$IS_WORKTREE" = true ]; then
  MAIN_ROOT=$(dirname "$COMMON_DIR")
  mkdir -p "$MAIN_ROOT/.tmp/handoff" "$WORKSPACE_ROOT/.tmp"
  if ln -s "$MAIN_ROOT/.tmp/handoff" "$HANDOFF_DIR" 2>/dev/null; then
    LINKED=true
  else
    warn "symlink not permitted (common on Windows); using a local directory instead"
    mkdir -p "$HANDOFF_DIR"
  fi
else
  if [ -L "$HANDOFF_DIR" ]; then
    LINKED=true
  fi
  mkdir -p "$HANDOFF_DIR"
fi

# --- 4. create the index if absent (never overwrite body via create) ------
CREATED_INDEX=false
UPGRADED=false
INDEX_VERSION=none

if [ ! -f "$HANDOFF_FILE" ]; then
  {
    printf '%s\n' '---'
    printf 'handoff-version: %s\n' "$PROTOCOL_VERSION"
    printf '%s\n' '---'
    printf '\n'
    printf '%s\n' '# Handoff Kanban'
    printf '\n'
    cat "$TEMPLATE"
    printf '\n'
    printf '%s\n' '(暂无动态)'
  } > "$HANDOFF_FILE"
  CREATED_INDEX=true
  INDEX_VERSION=$PROTOCOL_VERSION
  UPGRADED=false
else
  # existing index: mechanical protocol upgrade when stale
  upgrade_out=$("$SCRIPT_DIR/handoff-upgrade.sh" "$HANDOFF_FILE") || die "handoff-upgrade failed"
  # re-print select keys from upgrade; also keep full parse
  INDEX_VERSION=$(printf '%s\n' "$upgrade_out" | awk -F= '/^INDEX_VERSION=/{print $2; exit}')
  PROTO_FROM_UP=$(printf '%s\n' "$upgrade_out" | awk -F= '/^PROTOCOL_VERSION=/{print $2; exit}')
  UPGRADED=$(printf '%s\n' "$upgrade_out" | awk -F= '/^UPGRADED=/{print $2; exit}')
  [ -n "$PROTO_FROM_UP" ] && PROTOCOL_VERSION=$PROTO_FROM_UP
  # after upgrade, index version is current when UPGRADED=true
  if [ "$UPGRADED" = true ]; then
    INDEX_VERSION=$PROTOCOL_VERSION
  elif [ "$INDEX_VERSION" = none ] || [ -z "$INDEX_VERSION" ]; then
    INDEX_VERSION=$PROTOCOL_VERSION
  fi
fi

# --- 5. report ------------------------------------------------------------
printf 'WORKSPACE_ROOT=%s\n' "$WORKSPACE_ROOT"
printf 'HANDOFF_FILE=%s\n'   "$HANDOFF_FILE"
printf 'HANDOFF_DIR=%s\n'    "$HANDOFF_DIR"
printf 'IS_WORKTREE=%s\n'    "$IS_WORKTREE"
printf 'LINKED=%s\n'         "$LINKED"
printf 'CREATED_INDEX=%s\n'  "$CREATED_INDEX"
printf 'INDEX_VERSION=%s\n'  "$INDEX_VERSION"
printf 'PROTOCOL_VERSION=%s\n' "$PROTOCOL_VERSION"
printf 'UPGRADED=%s\n'       "$UPGRADED"
