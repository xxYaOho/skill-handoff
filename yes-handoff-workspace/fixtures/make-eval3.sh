#!/bin/sh
# make-eval3.sh <target-dir> — build the worktree-linking sandbox.
# Creates <dir>/main-repo plus a linked worktree <dir>/worktree-feature
# (branch feature/login-style) with uncommitted style changes inside it.
set -eu

dir="$1"
# Absolutize: git worktree add below resolves its target against $PWD, and the
# script cds into main-repo first — a relative $dir would nest the worktree
# inside main-repo instead of beside it.
dir="$(cd "$(dirname "$dir")" && pwd)/$(basename "$dir")"
if [ -e "$dir" ]; then
  echo "make-eval3: target already exists: $dir" >&2
  exit 1
fi
main="$dir/main-repo"
wt="$dir/worktree-feature"
mkdir -p "$main/src"
cd "$main"
git init -q
git config user.email eval@example.com
git config user.name eval

cat > package.json <<'EOF'
{
  "name": "login-page",
  "private": true,
  "version": "0.1.0",
  "type": "module"
}
EOF

cat > src/login.ts <<'EOF'
// Login page styles.
export const styles = {
  button: {
    padding: "8px 16px",
    borderRadius: "4px",
    background: "#ffffff",
    color: "#333333",
  },
};
EOF

git add -A
git commit -qm "init: login page scaffold"

git worktree add "$wt" -b feature/login-style -q

cd "$wt"
git config user.email eval@example.com
git config user.name eval
cat > src/login.ts <<'EOF'
// Login page styles.
export const styles = {
  button: {
    padding: "12px 24px",
    borderRadius: "8px",
    background: "#4f46e5",
    color: "#ffffff",
    boxShadow: "0 2px 8px rgba(79, 70, 229, 0.3)",
  },
};
EOF

echo "built eval-3 sandbox at $dir (worktree: $wt)"
