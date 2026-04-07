---
name: ecosystem.langgraph
description: 用于补充 LangGraph / AI 工作流平台类项目的识别与部署判断。适用于存在 graph、gateway、agent、sandbox、channels 等概念的复杂 AI 平台项目。
category: ecosystem
version: 1.0.0
---

# Skill: ecosystem.langgraph

## Purpose

帮助 Agent 识别 LangGraph 类项目常见的多服务和平台型特征。

## Trigger Signals

1. 文档或依赖中出现 `langgraph`
2. 仓库包含 `gateway`、`graph`、`agent`、`sandbox` 等运行角色
3. 项目属于 AI 工作流平台或编排平台

## Required Evidence

1. 文档或依赖中的 `langgraph`
2. 多服务目录结构和角色分布
3. 前端、网关、运行时服务之间的依赖关系
4. 外部模型、存储、消息通道或沙箱依赖

## Analysis Steps

1. 先按多服务平台处理
2. 再找官方 Compose、Dockerfile 或部署脚本
3. 再确认前端、网关、运行时服务之间的依赖

## Decision Hints

1. LangGraph 相关项目默认提高多服务概率
2. 优先使用编排入口，而不是单服务容器推断
3. 需要关注环境变量、外部模型服务和存储依赖

## Risk Guards

1. 不要把 AI 平台项目简化成单一 API 服务
2. 不要忽略外部依赖导致的“启动了但不可用”

## Stop Conditions

1. 核心依赖关系不清晰
2. 环境配置缺失严重

## Output Hints

1. `activeSkills` 应包含 `ecosystem.langgraph`
2. `risks` 应记录外部依赖、平台多角色和配置缺失问题
3. `requiresManualReview` 可在依赖关系不清时提升

## Related Skills

1. `architecture.multi-service`
2. `entrypoint.existing-compose`
3. `playbooks.deployment-decision`
