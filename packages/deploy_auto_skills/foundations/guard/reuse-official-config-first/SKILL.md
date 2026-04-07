---
name: guard.reuse-official-config-first
description: 风险约束 Skill。用于要求 Agent 在生成任何兜底部署方案前，优先查找并复用仓库已有的 Compose、Dockerfile、Makefile、脚本和 README 部署说明。
category: guard
version: 1.0.0
---

# Skill: guard.reuse-official-config-first

## Purpose

阻止 Agent 忽略仓库作者已经提供的部署知识。

## Trigger Signals

1. 仓库中存在 Compose、Dockerfile、Makefile、部署脚本或明确部署文档
2. Agent 准备进入通用生成路径
3. 项目存在多个可能入口，且至少一个属于仓库自带入口

## Required Evidence

在决定进入生成路径前，应至少检查：

1. 官方 Compose
2. 官方 Dockerfile
3. Makefile
4. 部署脚本
5. README / Install / docs 中的部署段落

## Analysis Steps

1. 先扫描仓库中的官方部署入口
2. 再确认这些入口是否完整、可执行、与目标环境兼容
3. 只有在官方入口不存在、不可用或证据不足时，才讨论兜底生成
4. 若已经存在高可信入口，应阻断生成路径

## Decision Hints

1. 默认优先复用仓库作者已提供的部署入口
2. 生成型能力只能作为最后兜底
3. 官方入口优先级应高于语言或生态推断

## Risk Guards

1. 仓库作者知识通常比推断更可靠
2. 自行生成部署文件很容易覆盖正确方案

## Stop Conditions

1. 已发现高可信官方部署入口
2. 尚未完成入口扫描

## Output Hints

1. `blockedActions` 应包含兜底生成相关动作
2. `reasoningSummary` 应记录“为什么复用”或“为什么未复用”
3. `recommendedStrategy` 应优先落在复用官方入口的分支

## Related Skills

1. `entrypoint.existing-compose`
2. `entrypoint.existing-dockerfile`
3. `playbooks.deployment-decision`
