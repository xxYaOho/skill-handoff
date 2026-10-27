#!/bin/sh
# handoff-upgrade.sh — if HANDOFF.md protocol is stale, refresh frontmatter
# version and replace the top blockquote from the skill template.
#
# Usage:
#   handoff-upgrade.sh <HANDOFF_FILE>
#
# Output (stdout, one KEY=VALUE per line):
#   INDEX_VERSION=<x.y|none>
#   PROTOCOL_VERSION=<x.y>
#   UPGRADED=true|false
#
# Diagnostics on stderr. Does not rewrite global/topic dynamics.

set -eu

die()  { printf 'handoff-upgrade: %s\n' "$1" >&2; exit 1; }
warn() { printf 'handoff-upgrade: %s\n' "$1" >&2; }

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
PROTOCOL_VERSION=$(tr -d ' \t\r\n' < "$SCRIPT_DIR/PROTOCOL_VERSION")
TEMPLATE="$SCRIPT_DIR/templates/blockquote.md"
[ -n "$PROTOCOL_VERSION" ] || die "PROTOCOL_VERSION is empty"
[ -f "$TEMPLATE" ] || die "missing template: $TEMPLATE"

HANDOFF_FILE=${1:-}
[ -n "$HANDOFF_FILE" ] || die "usage: handoff-upgrade.sh <HANDOFF_FILE>"
[ -f "$HANDOFF_FILE" ] || die "not a file: $HANDOFF_FILE"

normalize_ver() {
  printf '%s' "$1" | awk -F. '{
    if (NF < 1 || $1 == "") { print ""; exit }
    minor = (NF < 2 || $2 == "" ? 0 : $2)
    printf "%d.%d", $1+0, minor+0
  }'
}

version_lt() {
  a=$(normalize_ver "$1")
  b=$(normalize_ver "$2")
  [ -n "$a" ] && [ -n "$b" ] || return 0
  awk -v a="$a" -v b="$b" 'BEGIN {
    split(a, A, "."); split(b, B, ".");
    if (A[1] < B[1]) exit 0;
    if (A[1] > B[1]) exit 1;
    if (A[2] < B[2]) exit 0;
    exit 1;
  }'
}

read_index_version() {
  awk '
    NR == 1 && /^---[[:space:]]*$/ { in_fm = 1; next }
    in_fm && /^---[[:space:]]*$/ { exit }
    in_fm {
      if ($1 == "handoff-version:") {
        v = $2
        gsub(/\r/, "", v)
        print v
        exit
      }
    }
  ' "$1"
}

INDEX_RAW=$(read_index_version "$HANDOFF_FILE" || true)
if [ -z "${INDEX_RAW:-}" ]; then
  INDEX_VERSION=none
  NEED=true
else
  INDEX_VERSION=$(normalize_ver "$INDEX_RAW")
  if version_lt "$INDEX_VERSION" "$PROTOCOL_VERSION"; then
    NEED=true
  else
    NEED=false
  fi
fi

printf 'INDEX_VERSION=%s\n' "$INDEX_VERSION"
printf 'PROTOCOL_VERSION=%s\n' "$PROTOCOL_VERSION"

if [ "$NEED" != true ]; then
  printf 'UPGRADED=false\n'
  exit 0
fi

TITLE_FILE=$(mktemp)
BODY_FILE=$(mktemp)
OUT_TMP=$(mktemp)
trap 'rm -f "$TITLE_FILE" "$BODY_FILE" "$OUT_TMP"' EXIT

# Drop frontmatter; capture first # title; skip post-title blanks + leading
# blockquote (IMPORTANT or plain >); keep the rest as body.
awk -v title_out="$TITLE_FILE" -v body_out="$BODY_FILE" '
  BEGIN { in_fm = 0; saw_title = 0; phase = "pre" }
  NR == 1 && /^---[[:space:]]*$/ { in_fm = 1; next }
  in_fm {
    if (/^---[[:space:]]*$/) { in_fm = 0; next }
    next
  }
  phase == "pre" && /^[[:space:]]*$/ { next }
  phase == "pre" && /^#/ {
    print > title_out
    saw_title = 1
    phase = "after_title"
    next
  }
  phase == "after_title" && /^[[:space:]]*$/ { next }
  phase == "after_title" && /^>/ {
    phase = "in_bq"
    next
  }
  phase == "after_title" {
    phase = "body"
  }
  phase == "in_bq" && /^>/ { next }
  phase == "in_bq" && /^[[:space:]]*$/ { phase = "body"; next }
  phase == "in_bq" { phase = "body" }
  phase == "body" { print > body_out }
  END {
    if (!saw_title) print "# Handoff Kanban" > title_out
  }
' "$HANDOFF_FILE"

TITLE=$(cat "$TITLE_FILE")

{
  printf '%s\n' '---'
  printf 'handoff-version: %s\n' "$PROTOCOL_VERSION"
  printf '%s\n' '---'
  printf '\n'
  printf '%s\n' "$TITLE"
  printf '\n'
  cat "$TEMPLATE"
  if [ -s "$BODY_FILE" ]; then
    printf '\n'
    awk 'BEGIN{s=0} /^[[:space:]]*$/ && !s {next} {s=1; print}' "$BODY_FILE"
  fi
} > "$OUT_TMP"

[ -s "$OUT_TMP" ] || die "upgrade produced empty file"
mv "$OUT_TMP" "$HANDOFF_FILE"
rm -f "$TITLE_FILE" "$BODY_FILE"
trap - EXIT

printf 'UPGRADED=true\n'
warn "upgraded protocol ${INDEX_VERSION} -> ${PROTOCOL_VERSION}"
