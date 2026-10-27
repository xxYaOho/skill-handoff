#!/bin/sh
# make-eval4.sh <target-dir> — build the light-close sandbox.
# Login-page repo whose button-color work is committed and accepted,
# with a stale HANDOFF.md still saying the work is "in progress".
set -eu

dir="$1"
if [ -e "$dir" ]; then
  echo "make-eval4: target already exists: $dir" >&2
  exit 1
fi
mkdir -p "$dir/src"
cd "$dir"
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

# Stale index: written when the button work started, never updated since.
cat > HANDOFF.md <<'EOF'
# Handoff Kanban

> [!IMPORTANT]
> 1. 从下方全局动态及关联文档恢复工作状态，并派遣子代理（explore @haiku）对照工作区复验, 存在课题组时则先确认课题组, 再复验.
> 2. 向用户简要说明当前状态与下一步，若引用的 commit、分支或文件已失效，或工作区存在文档未记录的改动，明确指出差异
> 3. 汇报后进入待命状态, 等待下一步安排

登录页主按钮色改造进行中：indigo 方案已定，改完待用户验收。下一步：完成色值调整并请用户验收。
EOF

git add -A
git commit -qm "chore: scaffold with in-progress handoff index"

# This session's work: button color switched and accepted by the user.
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

git add -A
git commit -qm "feat: switch primary button to indigo palette"

echo "built eval-4 sandbox at $dir"
