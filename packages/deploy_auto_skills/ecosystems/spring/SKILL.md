---
name: ecosystem.spring
description: 用于补充 Spring / Spring Boot 项目的识别、构建线索和验证方式。适用于 Java Web 服务和多模块 Spring 工程。
category: ecosystem
version: 1.0.0
---

# Skill: ecosystem.spring

## Purpose

帮助 Agent 更准确地识别 Spring 生态项目。

## Trigger Signals

1. 存在 `pom.xml`、`build.gradle`
2. 文档中出现 `Spring`、`Spring Boot`
3. 项目表现为 Java 服务端应用

## Required Evidence

1. 依赖或插件中的 Spring 相关内容
2. `pom.xml`、`build.gradle`
3. 文档中的 `mvn package`、`gradle build` 和运行说明
4. 多模块关系、Dockerfile 或 Compose 入口

## Analysis Steps

1. 先看构建系统（Maven / Gradle）
2. 再看是否已有 Dockerfile 或脚本
3. 再定位运行入口和端口

## Decision Hints

1. Spring 项目通常更像服务或多模块服务，不应直接套 Node / Python 模板
2. 若已有 Dockerfile 或 Compose，应优先复用
3. 若只有构建系统而无明确部署入口，应先完成项目理解再决定是否容器化

## Risk Guards

1. 不要假设所有 Spring 项目都是单体 HTTP 服务
2. 不要忽略多模块 Maven / Gradle 结构

## Stop Conditions

1. 多模块关系不清晰
2. 找不到真实可运行模块

## Output Hints

1. `activeSkills` 应包含 `ecosystem.spring`
2. `risks` 应记录多模块关系、运行模块不清等问题
3. `reasoningSummary` 可明确 Spring 构建链与运行入口判断

## Related Skills

1. `artifact.web-service`
2. `entrypoint.existing-dockerfile`
3. `playbooks.deployment-decision`
