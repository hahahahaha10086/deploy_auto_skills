---
name: entrypoint.makefile
description: 用于识别 Makefile 作为项目官方入口的场景，帮助 Agent 优先复用 make 目标而不是自行拼接构建和启动命令。
category: entrypoint
version: 1.0.0
---

# Skill: entrypoint.makefile

## Purpose

帮助 Agent 优先把 Makefile 视为官方任务入口之一。

## Trigger Signals

1. 仓库存在 Makefile
2. README 明确说明使用 `make up`、`make run`、`make build`
3. Makefile 聚合了构建、启动、打包、清理等动作

## Required Evidence

1. `Makefile`
2. README 对 make target 的引用
3. 关键 target 的命令链与依赖关系
4. target 是否调用 Compose、脚本或其他构建系统

## Analysis Steps

1. 先看 README 是否引用 Makefile
2. 再提取关键 target
3. 再判断 target 是否适合部署流程
4. 区分部署 target、开发 target、测试 target 和清理 target

## Decision Hints

1. 被 README 明确引用的 make target 优先级很高
2. Makefile 可作为比 AI 推断更可靠的操作入口
3. 不要在已有明确 make 流程时绕过它

## Risk Guards

1. 不要把 `make test` 当部署入口
2. 不要忽略 Makefile 中的依赖关系和环境要求

## Stop Conditions

1. Makefile 目标含义不明确
2. 目标会进行高风险系统修改且缺少说明

## Output Hints

1. `entrypointCandidates` 应包含推荐 target 与来源
2. `recommendedStrategy` 可倾向 `reuse_makefile_or_script`
3. `blockedActions` 应避免绕过明确的官方 make 流程

## Related Skills

1. `entrypoint.script`
2. `entrypoint.readme`
3. `guard.reuse-official-config-first`
