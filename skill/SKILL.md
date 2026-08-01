---
name: yes-handoff
description: >
  继承上个会话或目标的资料信息, 快速进入工作状态.
---

# Yes! Handoff Work

维护上下文卫生, 创建和撰写全面的交接文档, 让 agent 在 new session 无缝继续完成工作, 零歧义. 

### 准备工作

1. 确认工作区是否存在 HANDOFF.md, 不存在则初始化环境

```bash
cp template/HANDOFF.md $WORKSPACE_ROOT_DIR/HANDOFF.md
mkdir -p $WORKSPACE_ROOT_DIR/.tmp/handoff
```

2. 确认所在工作区为子区 (worktree), 确认是子区则创建一个 symlink, 将主区中的 `.tmp/handoff` 链接到当前工作区中.
## Handoff

编写一份交接文档，总结当前对话内容，以便 freah-agent 能够继续工作。将文档保存到当前工作区的临时目录 `.tmp/handoff/YYMMDDhhssmm-<title>.md`。

在文档中包含一个“建议技能”部分，列出代理应调用的技能建议。

不要重复其他工件（如规格说明、计划、ADR、问题、提交、差异）中已捕获的内容。改为通过路径或 URL 引用它们。

对任何敏感信息进行脱敏处理，例如 API 密钥、密码或个人身份信息。

如果用户传入了参数，请将其视为对下一阶段工作重点的描述，并据此调整文档内容。

完成后, 在 HANDOFF.md 更新最新动态, 附上交接文档的链接.

> 规则
> - 最新动态的描述文字 ≤ 400 字数, 接近上限时, 压缩或移除过时内容;
> - 交接文档通常不再二次编辑, 允许沿用同个标题, 增加标记就可以, 比如 `YYMMDDhhssmm-<title>-V<number>.md`, 默认 V1 无标记

## Advanced: Topics

handoff 的进阶模式, 主题聚合. 当多项工作任务交织在一起, 无法在 HANDOFF.md 最新动态中体现时, 考虑按主题聚合同类工作.

```
# Handoff Kanban

全局动态

## T1: 标题

最新动态

[文档](.tmp/handoff/YYMMDDhhssmm-<title>.md)

## T2: 标题

最新动态

[文档](.tmp/handoff/YYMMDDhhssmm-<title>.md)
```


