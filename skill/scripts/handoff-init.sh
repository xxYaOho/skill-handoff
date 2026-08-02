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

# --- 4. create the index if absent (never overwrite) ----------------------
CREATED_INDEX=false
if [ ! -f "$HANDOFF_FILE" ]; then
  cat > "$HANDOFF_FILE" <<'INDEX'
# Handoff Kanban

> 接手说明: 从下方全局动态及其关联文档中恢复工作状态, 向用户简要说明已知现状与下一步.
> 存在课题组时, 额外提供课题组列表 (代号和一句话描述).
> 若引用的 commit / 分支 / 文件已不存在, 或工作区存在文档未提及的改动, 先向用户指出差异.
> 接手后先做一次简单复验: 派遣子代理 (skill: yes-subagent) 复查文档的真实性, 核对其陈述与工作区实际状态是否一致, 差异之处向用户指出.
> 说明完毕后等待用户的进一步安排, 不要自行开工.

(暂无动态)
INDEX
  CREATED_INDEX=true
fi

# --- 5. report ------------------------------------------------------------
printf 'WORKSPACE_ROOT=%s\n' "$WORKSPACE_ROOT"
printf 'HANDOFF_FILE=%s\n'   "$HANDOFF_FILE"
printf 'HANDOFF_DIR=%s\n'    "$HANDOFF_DIR"
printf 'IS_WORKTREE=%s\n'    "$IS_WORKTREE"
printf 'LINKED=%s\n'         "$LINKED"
printf 'CREATED_INDEX=%s\n'  "$CREATED_INDEX"
