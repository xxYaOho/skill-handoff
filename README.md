# yes-handoff

上下文交接技能（Agent Skill）：将当前对话浓缩成一份交接文件，由 fresh-agent 在新 session 无缝继续处理。

详细说明见 `skill/SKILL.md`。

## 安装

```bash
git clone https://github.com/xxYaOho/skill-handoff.git
cd skill-handoff

mkdir -p ~/.agents/skills
ln -s "$(pwd)/skill" ~/.agents/skills/yes-handoff
```

技能本体在 `skill/` 目录（含 `SKILL.md`）。`~/.agents/skills/` 是跨工具通用目录：Claude Code、Kimi Code、Codex、DeepSeek Harness 都会扫描；用符号链接挂载，仓库更新后即时生效。

各 CLI 的技能目录一览：

| CLI | 用户级技能目录 |
| --- | --- |
| Claude Code | `~/.claude/skills/`，也读 `~/.agents/skills/` |
| Kimi Code CLI | `~/.kimi-code/skills/`（随 `$KIMI_CODE_HOME` 移动），也读 `~/.agents/skills/` |
| Codex CLI | `~/.agents/skills/`（跨工具通用目录；项目级为 `<repo>/.agents/skills/`） |
| DeepSeek Harness | `~/.agents/skills/`（作为共享 Agent 技能根加载） |

如需隔离到某个 CLI，换对应目录即可，例如 Claude Code：

```bash
mkdir -p ~/.claude/skills
ln -s "$(pwd)/skill" ~/.claude/skills/yes-handoff
```

注意：链接名必须叫 `yes-handoff`，与 `skill/SKILL.md` frontmatter 里的 `name` 一致；链接目标必须是包含 `SKILL.md` 的目录本身，不要链到仓库根。

验证安装：

```bash
ls ~/.agents/skills/yes-handoff/SKILL.md
```

## 卸载

```bash
unlink ~/.agents/skills/yes-handoff   # 只删链接，不影响仓库
```
