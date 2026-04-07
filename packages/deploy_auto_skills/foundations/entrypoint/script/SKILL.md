---
name: entrypoint.script
description: 用于识别并优先复用仓库自带的部署脚本或启动脚本，例如 deploy.sh、start.sh、bootstrap.sh、run.ps1 等，避免忽略项目作者提供的一键流程。
category: entrypoint
version: 1.0.0
---

# Skill: entrypoint.script

## Purpose

帮助 Agent 把仓库已有脚本视为重要部署证据。

## Trigger Signals

1. 仓库存在明显的启动、部署、安装脚本
2. README 中明确引用脚本执行方式
3. 项目依赖脚本组织多个步骤

## Required Evidence

1. 部署或启动脚本，如 `deploy.sh`、`start.sh`、`bootstrap.sh`、`run.ps1`
2. `scripts/`、`deploy/` 等目录
3. README 中对脚本的引用方式
4. 脚本中的关键构建、启动、校验步骤

## Analysis Steps

1. 先看 README 是否引用脚本
2. 再看脚本本身做了哪些动作
3. 再判断脚本是开发用途还是生产部署用途
4. 识别脚本是否依赖特定 shell、权限或目录上下文

## Decision Hints

1. 明确被文档引用的脚本应优先检查
2. 若脚本组织了完整流程，应优先复用而不是重建流程
3. 若脚本明显只用于开发调试，需要降级优先级

## Risk Guards

1. 不要把测试脚本当部署脚本
2. 不要执行来源不明且破坏性强的脚本

## Stop Conditions

1. 脚本行为不明且副作用过大
2. 脚本依赖外部环境但无法确认

## Output Hints

1. `entrypointCandidates` 应包含脚本路径、shell 类型和用途判断
2. `environmentRisks` 可记录脚本与目标环境不兼容的风险
3. `recommendedStrategy` 可倾向 `reuse_makefile_or_script`

## Related Skills

1. `entrypoint.makefile`
2. `environment.windows`
3. `guard.reuse-official-config-first`
