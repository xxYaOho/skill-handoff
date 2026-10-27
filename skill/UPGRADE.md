# Protocol upgrade

索引 `HANDOFF.md` 文首 frontmatter 的 `handoff-version`（`major.minor`）标记协议代际。运行 `scripts/handoff-init.sh` 时：

- 若索引不存在：按当前模板新建（含 frontmatter + blockquote）。
- 若索引存在且 `handoff-version` 缺失或 **&lt;** `scripts/PROTOCOL_VERSION`：调用 `scripts/handoff-upgrade.sh`，**机械**写入 frontmatter，并用 `scripts/templates/blockquote.md` **整段替换**文首接手 blockquote；全局/课题组动态不动。
- 若已是当前版本：不改文件。

Agent **不要**手改 blockquote 来「对齐新协议」——走 init/upgrade。日常交接仍禁止改写 blockquote；**唯一例外**是上述脚本升级。

对照只比到 minor（`0.5.1` skill 元数据对应协议 `0.5`）。

## 代际摘要

### → 0.5

- 引入 frontmatter `handoff-version`
- blockquote：≥2 课题组时先 ASK（选项 +「只看全局 / 我自己说」），选定前不得 explore / 深读 / 复验 / 开工
