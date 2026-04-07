---
name: entrypoint.readme
description: 用于把 README、Install 文档和 docs 中的部署说明视为高价值入口线索。适用于项目作者通过文档而不是配置文件给出启动和部署路径的场景。
category: entrypoint
version: 1.0.0
---

# Skill: entrypoint.readme

## Purpose

帮助 Agent 从 README 和安装文档中提取可信部署入口，而不是只盯着文件名做机械判断。

## Trigger Signals

1. 仓库没有明显的顶层部署配置
2. README、Install、docs 中存在 Quick Start、Deployment、Install 等章节
3. 项目作者通过文档描述启动顺序和环境要求

## Required Evidence

1. `README.md`、`Install.md`、`docs/` 中的部署相关段落
2. 命令块、目录路径、端口、访问地址、依赖说明
3. 文档中引用的脚本、Dockerfile、Compose 或工作目录
4. 文档与仓库实际结构的一致性

## Analysis Steps

1. 先找 README 中的部署和运行段落
2. 再找 Install 或 docs 中的详细步骤
3. 提取命令、目录、依赖、环境变量和访问方式
4. 将文档步骤与实际文件、脚本和配置交叉验证

## Decision Hints

1. README 中被明确标注的部署步骤优先级很高
2. 若 README 与配置文件冲突，需继续交叉验证
3. 文档可作为没有显式 Compose / Dockerfile 时的重要入口依据

## Risk Guards

1. 不要只看 README 前几行介绍
2. 不要把开发说明误当成生产部署说明

## Stop Conditions

1. README 过旧、冲突严重或明显不完整
2. 关键步骤缺少必要上下文

## Output Hints

1. `entrypointCandidates` 应记录文档来源、章节位置和可信度
2. `recommendedStrategy` 可倾向 `reuse_documented_manual_flow`
3. `risks` 应记录文档过旧、冲突或不完整风险

## Related Skills

1. `entrypoint.script`
2. `entrypoint.makefile`
3. `guard.reuse-official-config-first`
