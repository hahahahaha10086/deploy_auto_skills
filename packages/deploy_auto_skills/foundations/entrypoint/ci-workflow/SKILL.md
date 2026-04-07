---
name: entrypoint.ci-workflow
description: 用于从 GitHub Actions 等 CI workflow 中提取构建、测试、打包和启动线索。适用于 README 不充分但 CI 足够规范的项目。
category: entrypoint
version: 1.0.0
---

# Skill: entrypoint.ci-workflow

## Purpose

帮助 Agent 把 CI workflow 视为“项目维护者真实使用的构建与运行证据”。

## Trigger Signals

1. 存在 `.github/workflows/`
2. workflow 中包含构建、测试、打包、发布命令
3. README 不足以说明完整部署路径

## Required Evidence

1. `.github/workflows/*.yml`
2. workflow 中的语言设置、工作目录、安装和构建命令
3. workflow 中的发布、打包或镜像构建步骤
4. 与 README / 脚本 / Dockerfile 的一致性

## Analysis Steps

1. 先识别 workflow 中的语言设置
2. 再提取安装、构建、启动、打包命令
3. 再判断这些命令是开发验证还是发布入口
4. 识别 workflow 是否依赖矩阵、私有环境或外部凭据

## Decision Hints

1. CI 中的构建链通常比猜测更可靠
2. CI 可作为 README 的补充证据，不应单独覆盖仓库官方部署入口
3. 若 CI 与 README 冲突，需要进入人工审查或二次分析

## Risk Guards

1. 不要把测试流水线直接当生产部署流水线
2. 不要忽略 workflow 中的工作目录和矩阵配置

## Stop Conditions

1. workflow 只包含测试，不包含构建或部署信息
2. workflow 严重依赖外部私有环境

## Output Hints

1. `entrypointCandidates` 可记录 CI 作为补充证据来源
2. `risks` 应记录私有环境依赖、矩阵复杂度或与 README 冲突
3. `requiresManualReview` 可在 CI 与官方文档冲突时提升

## Related Skills

1. `entrypoint.readme`
2. `build.pnpm-workspace`
3. `guard.reuse-official-config-first`
