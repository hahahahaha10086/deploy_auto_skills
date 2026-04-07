---
name: entrypoint.existing-compose
description: 用于优先发现并复用仓库已有的 Compose 编排入口。适用于根目录或子目录存在 compose 文件的项目，尤其适合多服务和复杂部署结构。
category: entrypoint
version: 1.0.0
---

# Skill: entrypoint.existing-compose

## Purpose

帮助 Agent 把仓库已有 Compose 视为高优先级官方部署入口。

## Trigger Signals

1. 仓库存在 `docker-compose.yml`、`docker-compose.yaml`、`compose.yml`、`compose.yaml`
2. Compose 位于 `docker/`、`deploy/`、`ops/` 等子目录
3. 项目存在多服务或服务依赖

## Required Evidence

1. 根目录及部署相关子目录中的 Compose 文件
2. README / docs 中关于 Compose 的说明
3. Compose 所在目录中的 `.env`、覆盖文件、依赖配置
4. Compose 文件中的 `services`、`depends_on`、`build`、`ports` 等关键字段

## Analysis Steps

1. 先扫描根目录
2. 再扫描 `docker/`、`deploy/`、`ops/`、`infra/`
3. 再扫描 README 中提到的部署目录
4. 对多个 Compose 文件按目录语义和文档说明排序
5. 确认 Compose 是否依赖额外环境变量、覆盖文件或外部配置

## Decision Hints

1. 一旦发现官方 Compose，默认优先复用
2. 复用优先级高于生成单服务 Dockerfile
3. 若有多个 Compose 文件，需结合 README 和目录语义排序

## Risk Guards

1. 不要只扫根目录
2. 不要在发现 Compose 后仍直接退化成单服务推断

## Stop Conditions

1. 多个 Compose 文件冲突且文档未说明差异
2. Compose 依赖外部配置但无法识别来源

## Output Hints

1. `entrypointCandidates` 中应包含 Compose 路径、来源和优先级
2. `recommendedStrategy` 应倾向 `reuse_existing_compose`
3. `blockedActions` 可包含根目录兜底 Dockerfile 生成
4. `risks` 应记录多 Compose 冲突或外部配置缺失风险

## Related Skills

1. `architecture.multi-service`
2. `entrypoint.readme`
3. `guard.reuse-official-config-first`
