#!/bin/sh
# make-eval1.sh <target-dir> — build the basic-handoff sandbox repo.
# A mini TS config-parser project: 3 commits, one uncommitted new file.
set -eu

dir="$1"
if [ -e "$dir" ]; then
  echo "make-eval1: target already exists: $dir" >&2
  exit 1
fi
mkdir -p "$dir/src"
cd "$dir"
git init -q
git config user.email eval@example.com
git config user.name eval

cat > package.json <<'EOF'
{
  "name": "mini-config-cli",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "test": "node --test src/parser.test.ts"
  }
}
EOF

cat > src/parser.ts <<'EOF'
// Config parser — regex-based first attempt.
export interface ConfigNode {
  key: string;
  value: string;
}

export function parseConfig(input: string): ConfigNode[] {
  const nodes: ConfigNode[] = [];
  const re = /^\s*([A-Za-z0-9_.-]+)\s*=\s*(.+?)\s*$/gm;
  let m: RegExpExecArray | null;
  while ((m = re.exec(input)) !== null) {
    nodes.push({ key: m[1], value: m[2] });
  }
  return nodes;
}
EOF

git add -A
git commit -qm "init: project scaffold with regex parser"

cat > src/parser.ts <<'EOF'
// Config parser — AST-based rewrite.
// Handles nested sections like `[server.http]` correctly.
export interface ConfigNode {
  key: string;
  value: string | ConfigNode[];
}

interface Frame {
  node: ConfigNode;
  indent: number;
}

export function parseConfig(input: string): ConfigNode[] {
  const roots: ConfigNode[] = [];
  const stack: Frame[] = [];

  for (const raw of input.split("\n")) {
    const line = raw.trimEnd();
    if (!line || line.startsWith("#")) continue;
    const indent = raw.length - raw.trimStart().length;
    const eq = line.indexOf("=");
    const node: ConfigNode =
      eq === -1
        ? { key: line.trim(), value: [] }
        : { key: line.slice(0, eq).trim(), value: line.slice(eq + 1).trim() };

    while (stack.length > 0 && stack[stack.length - 1].indent >= indent) {
      stack.pop();
    }
    if (stack.length === 0) {
      roots.push(node);
    } else {
      const parent = stack[stack.length - 1].node;
      if (typeof parent.value === "string") parent.value = [];
      (parent.value as ConfigNode[]).push(node);
    }
    stack.push({ node, indent });
  }
  return roots;
}
EOF

git add -A
git commit -qm "refactor: rewrite parser with AST approach"

cat > src/parser.test.ts <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { parseConfig } from "./parser.ts";

test("parses flat key=value pairs", () => {
  const nodes = parseConfig("host = localhost\nport = 8080");
  assert.equal(nodes.length, 2);
  assert.deepEqual(nodes[0], { key: "host", value: "localhost" });
});

test("parses nested sections by indentation", () => {
  const nodes = parseConfig("[server]\n  host = localhost\n  port = 8080");
  assert.equal(nodes.length, 1);
  assert.equal(nodes[0].key, "[server]");
  assert.ok(Array.isArray(nodes[0].value));
});
EOF

git add -A
git commit -qm "test: add parser tests"

# Uncommitted work in progress:
cat > src/cli.ts <<'EOF'
// CLI entry — WIP, not finished.
// TODO: wire up parseConfig, add --format flag.
import { parseConfig } from "./parser.ts";

const file = process.argv[2];
if (!file) {
  console.error("usage: mini-config <file>");
  process.exit(1);
}
console.log(parseConfig(file));
EOF

echo "built eval-1 sandbox at $dir"
