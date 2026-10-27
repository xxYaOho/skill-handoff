#!/bin/sh
# make-eval6.sh <target-dir> — build the delivery-keeps-topic-alive sandbox.
# A repo whose HANDOFF.md (fixture e6) already records T1 model-router as
# delivered and accepted this round, with the linked handoff document in place.
set -eu

dir="$1"
if [ -e "$dir" ]; then
  echo "make-eval6: target already exists: $dir" >&2
  exit 1
fi
mkdir -p "$dir/.tmp/handoff" "$dir/src/router"
cd "$dir"
git init -q
git config user.email eval@example.com
git config user.name eval

# Index fixture (T1 delivered this round, topic stays active).
cp "$SESSION_ROOT/evals/files/e6-delivered-HANDOFF.md" HANDOFF.md

cat > .tmp/handoff/260911223340-model-router-v017.md <<'EOF'
# model-router — v0.17 交付交接

复验要点: pnpm test 绿 (路由回归用例 src/router/router.test.ts, 实测通过)。
v0.17 变更: 灰度比例配置迁入 src/router/config.ts, 兼容旧 env 变量 (ROUTER_RATIO_* / GRAY_RELEASE_RATIO)。
EOF

cat > package.json <<'EOF'
{
  "name": "model-router",
  "private": true,
  "version": "0.17.0",
  "type": "module",
  "scripts": {
    "test": "node --test src/router/router.test.ts"
  }
}
EOF

cat > src/router/router.ts <<'EOF'
// model-router — v0.17 delivered.
export interface RouteTarget {
  name: string;
  weight: number;
}

export function pickTarget(targets: RouteTarget[], roll: number): RouteTarget {
  const total = targets.reduce((sum, t) => sum + t.weight, 0);
  let acc = 0;
  for (const t of targets) {
    acc += t.weight;
    if (roll * total <= acc) return t;
  }
  return targets[targets.length - 1];
}
EOF

cat > src/router/config.ts <<'EOF'
// Grayscale ratio config — migrated here in v0.17 (was inline in router.ts).
// Backwards compatible with legacy env variables.
export const DEFAULT_RATIO = 0.2;

export function grayscaleRatio(
  env: Record<string, string | undefined> = process.env,
): number {
  const raw = env.ROUTER_RATIO ?? env.GRAY_RELEASE_RATIO;
  const n = raw === undefined ? NaN : Number(raw);
  return Number.isFinite(n) ? n : DEFAULT_RATIO;
}
EOF

cat > src/router/router.test.ts <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { pickTarget } from "./router.ts";
import { grayscaleRatio } from "./config.ts";

test("picks target by cumulative weight", () => {
  const targets = [
    { name: "a", weight: 3 },
    { name: "b", weight: 1 },
  ];
  assert.equal(pickTarget(targets, 0.0).name, "a");
  assert.equal(pickTarget(targets, 0.7).name, "a");
  assert.equal(pickTarget(targets, 0.9).name, "b");
});

test("returns last target on boundary roll", () => {
  const targets = [
    { name: "a", weight: 0 },
    { name: "b", weight: 2 },
  ];
  assert.equal(pickTarget(targets, 1).name, "b");
});

test("grayscaleRatio reads legacy env and falls back to default", () => {
  assert.equal(grayscaleRatio({ ROUTER_RATIO: "0.5" }), 0.5);
  assert.equal(grayscaleRatio({ GRAY_RELEASE_RATIO: "0.1" }), 0.1);
  assert.equal(grayscaleRatio({ ROUTER_RATIO: "abc" }), 0.2);
});
EOF

git add -A
git commit -qm "release: v0.17 delivered and accepted"

echo "built eval-6 sandbox at $dir"
