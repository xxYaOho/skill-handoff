#!/bin/sh
# make-eval2.sh <target-dir> — build the monorepo-topics sandbox.
# Mini Raycast-plugins monorepo with two independent plugins and a stale HANDOFF.md.
set -eu

dir="$1"
if [ -e "$dir" ]; then
  echo "make-eval2: target already exists: $dir" >&2
  exit 1
fi
mkdir -p "$dir/plugins/gemmadict/src" "$dir/plugins/talk-to-me/src"
cd "$dir"
git init -q
git config user.email eval@example.com
git config user.name eval

cat > package.json <<'EOF'
{
  "name": "app-raycast-plugins",
  "private": true,
  "version": "0.0.0",
  "workspaces": ["plugins/*"],
  "scripts": {
    "build": "npm run build --workspaces --if-present"
  }
}
EOF

cat > plugins/gemmadict/package.json <<'EOF'
{
  "name": "gemmadict",
  "private": true,
  "version": "0.1.0",
  "description": "翻译与词典。支持本地模型服务（如 LM Studio）。",
  "scripts": { "build": "echo build gemmadict" }
}
EOF

cat > plugins/gemmadict/src/translate.ts <<'EOF'
// gemmadict — translate command.
// Local model backend (LM Studio, OpenAI-compatible /v1/chat/completions).
export interface TranslateOptions {
  endpoint: string;
  model: string;
  text: string;
  targetLang: string;
}

export async function translate(opts: TranslateOptions): Promise<string> {
  const res = await fetch(`${opts.endpoint}/v1/chat/completions`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      model: opts.model,
      messages: [
        { role: "system", content: `Translate to ${opts.targetLang}.` },
        { role: "user", content: opts.text },
      ],
      stream: false,
    }),
  });
  const data = (await res.json()) as {
    choices: { message: { content: string } }[];
  };
  return data.choices[0].message.content;
}
EOF

cat > plugins/talk-to-me/package.json <<'EOF'
{
  "name": "talk-to-me",
  "private": true,
  "version": "0.1.0",
  "description": "语音优先的本地 AI 助手：录音转写 + LLM 调度。",
  "scripts": { "build": "echo build talk-to-me" }
}
EOF

cat > plugins/talk-to-me/src/transcribe.ts <<'EOF'
// talk-to-me — whisper.cpp transcription bridge.
// NOTE: integration not working yet; suspected sample-rate mismatch (unverified).
export interface TranscribeOptions {
  wavPath: string;
  modelPath: string;
}

export async function transcribe(opts: TranscribeOptions): Promise<string> {
  // TODO: spawn whisper-cli, parse output.
  // Recording comes in at 48kHz; whisper expects 16kHz — conversion missing.
  throw new Error(`not implemented: ${opts.wavPath} ${opts.modelPath}`);
}
EOF

# Index fixture: single source of truth lives in evals/files/.
cp "$SESSION_ROOT/evals/files/e2-stale-HANDOFF.md" HANDOFF.md

git add -A
git commit -qm "feat: monorepo scaffold with gemmadict and talk-to-me"

# second commit: local backend wired up
cat > plugins/gemmadict/src/config.ts <<'EOF'
export const DEFAULT_ENDPOINT = "http://localhost:1234";
export const DEFAULT_MODEL = "qwen2.5-7b-instruct";
EOF

git add -A
git commit -qm "feat(gemmadict): wire up LM Studio local backend"

echo "built eval-2 sandbox at $dir"
