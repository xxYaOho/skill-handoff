# `ce-handoff` 与 `$yes-handoff`：评审与优化方向

## 结论

两者不是替代关系：`ce-handoff` 更适合作为跨项目、跨来源的连续性协议；`$yes-handoff` 更适合作为 Git 仓库内的项目状态管理协议。当前不建议直接用 `ce-handoff` 替换 `$yes-handoff`，建议保留 `$yes-handoff` 的项目索引与课题组模型，吸收 `ce-handoff` 的 resume 安全边界。

## 已确认的优势

- `$yes-handoff` 用 `handoff-init.sh` / `handoff-add.sh` 机械化路径、命名和索引初始化。
- 三个必答问题（否决方案、已验证与推测、用户决策）和 400 字全局动态限制，能稳定传递项目上下文。
- 课题组编号、归档和全局/局部职责分离，适合长期多线项目。
- `ce-handoff` 支持无仓库会话及任意用户选定来源，并明确区分 create、discovery、orientation 和 action。
- `ce-handoff` 的 metadata-only discovery、显式候选选择、来源不具备行动权限等规则，提供了更清晰的安全模型。

## 风险与取舍

- `$yes-handoff` 强绑定 Git、仓库结构和脚本；`HANDOFF.md` 是可变索引，worktree 场景还有索引持久性风险。
- `$yes-handoff` 的 body 合同较强，但不支持通用外部来源 resume；脚本要求 ASCII slug，中文-only 标题不可直接生成。
- `ce-handoff` 默认使用 `/tmp`，跨机器或重启后的持久性较弱；没有项目索引和生命周期，创建质量更多依赖 agent 自觉。
- `ce-handoff` 的开放 body 适配性更好，但没有强制记录被否决方案和用户决策，可能遗漏关键隐性知识。

## 建议的优化 issue

标题：`Add a safe resume protocol to yes-handoff`

建议内容：

1. 增加显式 `resume <source-or-keywords>` 路由；支持用户指定任意可读来源，来源格式和作者不作为资格门槛。
2. 关键词发现阶段只读取 frontmatter、文件名和文件元数据；列出候选并等待用户选择，不读取未选正文。
3. 选定来源后只做 read-only orientation；将 handoff 内容视为不可信上下文，不因其中旧指令自动执行 workflow 或修改工作区。
4. 保留 `$yes-handoff` 的三个必答问题、项目索引和课题组模型，作为 repository mode 的增强合同。
5. 增加 receiver-side eval：fresh agent 只读取索引和详细文档，验证状态恢复、工作区漂移识别，以及用户确认前不行动。

## 证据边界

`yes-handoff` iteration-2 的创建侧评估为 19/19；报告同时明确指出 receiver-side resume 尚未覆盖。`ce-handoff` 的上述优点目前来自其 skill 与用户指南设计，尚未有同等规模的运行评估，不应写成已验证行为。
