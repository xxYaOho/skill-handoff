#!/bin/sh
# handoff-add.sh — create a blank handoff document with a spec-compliant name.
#
# Usage:
#   handoff-add.sh -n <title> [-s <suffix>]
#
#   -n <title>   document title; will be slugified to kebab-case ASCII,
#                at most 5 words (extra words are rejected, not truncated)
#   -s <suffix>  optional suffix appended after the title (e.g. V2 for a
#                continuation of an earlier document)
#
# Output (stdout, one KEY=VALUE per line):
#   HANDOFF_DOC=<abs path>   path of the newly created document
#
# The file name is <YYMMDDhhmmss>-<title>[-<suffix>].md, generated here so
# the naming spec is enforced by the script rather than by the agent.
#
# Diagnostics go to stderr. Exit code is non-zero on failure.

set -eu

die() { printf 'handoff-add: %s\n' "$1" >&2; exit 1; }

title=""
suffix=""
while [ $# -gt 0 ]; do
  case "$1" in
    -n) shift; title="${1:-}" ;;
    -s) shift; suffix="${1:-}" ;;
    *)  die "unknown argument: $1" ;;
  esac
  shift || true
done

[ -n "$title" ] || die "usage: handoff-add.sh -n <title> [-s <suffix>]"

# --- slugify: lowercase, non-alnum runs -> single dash, trim dashes ---------
slug=$(printf '%s' "$title" \
  | tr 'A-Z' 'a-z' \
  | sed -e 's/[^a-z0-9][^a-z0-9]*/-/g' -e 's/^-*//' -e 's/-*$//')
[ -n "$slug" ] || die "title has no usable ASCII characters: $title"

words=$(printf '%s' "$slug" | awk -F- '{print NF}')
[ "$words" -le 5 ] || die "title has $words words after slugification (max 5): $slug"

if [ -n "$suffix" ]; then
  clean_suffix=$(printf '%s' "$suffix" | sed -e 's/[^A-Za-z0-9]\+//g')
  [ -n "$clean_suffix" ] || die "suffix has no usable characters: $suffix"
  slug="$slug-$clean_suffix"
fi

# --- resolve HANDOFF_DIR via handoff-init.sh (single source of truth) -------
SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
INIT_OUT=$(sh "$SCRIPT_DIR/handoff-init.sh") || die "handoff-init.sh failed"
HANDOFF_DIR=$(printf '%s\n' "$INIT_OUT" | sed -n 's/^HANDOFF_DIR=//p')
[ -n "$HANDOFF_DIR" ] || die "handoff-init.sh did not report HANDOFF_DIR"

# --- create the document -----------------------------------------------------
doc="$HANDOFF_DIR/$(date +%y%m%d%H%M%S)-$slug.md"
if [ -e "$doc" ]; then
  die "document already exists (same second, same title): $doc"
fi
: > "$doc"

printf 'HANDOFF_DOC=%s\n' "$doc"
