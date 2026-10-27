#!/bin/sh
# make-eval5.sh <target-dir> — build the resume-ask sandbox.
# A repo with a two-topic HANDOFF.md (fixture e5) and the two linked handoff
# documents as placeholders. The placeholders carry unique detail tokens so a
# grader can tell whether an agent deep-read them (the protocol says: ask the
# user which topic to resume BEFORE deep-reading).
set -eu

dir="$1"
if [ -e "$dir" ]; then
  echo "make-eval5: target already exists: $dir" >&2
  exit 1
fi
mkdir -p "$dir/.tmp/handoff" "$dir/plugins/gemmadict/src" "$dir/plugins/talk-to-me/src"
cd "$dir"
git init -q
git config user.email eval@example.com
git config user.name eval

# Index fixture (two active topics).
cp "$SESSION_ROOT/evals/files/e5-topics-HANDOFF.md" HANDOFF.md

# Placeholder documents referenced by the index. Unique tokens inside
# (LM-port-1234-temperature-0.3 / sox-resample-candidate) exist ONLY here,
# so quoting them in the final report proves deep reading.
cat > .tmp/handoff/260901120000-gemmadict-local-model.md <<'EOF'
# gemmadict — 本地模型接入交接

复验要点: LM Studio 默认端口 1234, 模型 qwen2.5-7b-instruct, 温度 0.3 (LM-port-1234-temperature-0.3)。
翻译命令验收: 对 "hello world" 应输出 "你好，世界"; 错误态与超时提示未做。
EOF

cat > .tmp/handoff/260901120000-talk-to-me-whisper.md <<'EOF'
# talk-to-me — whisper 集成交接

复验要点: 录音 48kHz, whisper.cpp 期望 16kHz, 重采样工具候选 sox (sox-resample-candidate)。
基线样本 fixtures/sample-48k.wav 尚未生成, 先补样本再验证转换链路。
EOF

# Minimal plugin scaffolds so the workspace matches the index narrative.
cat > package.json <<'EOF'
{
  "name": "app-raycast-plugins",
  "private": true,
  "version": "0.0.0",
  "workspaces": ["plugins/*"]
}
EOF

cat > plugins/gemmadict/package.json <<'EOF'
{
  "name": "gemmadict",
  "private": true,
  "version": "0.1.0",
  "description": "翻译与词典。支持本地模型服务（如 LM Studio）。"
}
EOF

cat > plugins/talk-to-me/package.json <<'EOF'
{
  "name": "talk-to-me",
  "private": true,
  "version": "0.1.0",
  "description": "语音优先的本地 AI 助手：录音转写 + LLM 调度。"
}
EOF

git add -A
git commit -qm "chore: two-topic handoff state"

echo "built eval-5 sandbox at $dir"
