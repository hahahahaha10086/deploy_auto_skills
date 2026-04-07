---
name: ecosystem.fastapi
description: 用于补充 FastAPI 项目的识别、运行入口和验证方式。适用于 API 服务、Python Web 服务和容器化后端场景。
category: ecosystem
version: 1.0.0
---

# Skill: ecosystem.fastapi

## Purpose

帮助 Agent 更准确地识别 FastAPI 服务及其常见运行方式。

## Trigger Signals

1. 依赖中出现 `fastapi`
2. 文档中出现 `uvicorn`
3. 代码或文档中出现 `app = FastAPI()`

## Required Evidence

1. 依赖中的 `fastapi`、`uvicorn`
2. 文档中的 `uvicorn` 命令和模块路径
3. 代码中的 ASGI 入口，如 `app = FastAPI()`
4. 现有 Dockerfile、Compose 或 Python 依赖管理方式

## Analysis Steps

1. 先看是否已有 Dockerfile 或 Compose
2. 再看 README 中的 `uvicorn` 命令
3. 再定位实际模块路径和健康检查路径

## Decision Hints

1. 若文档已明确 `uvicorn` 命令，优先采用其模块路径
2. 若存在系统级编排入口，应服从系统级入口
3. 若是单独 API 服务，可作为较高可信自动部署对象

## Risk Guards

1. 不要假设所有 FastAPI 服务都在 `app.main:app`
2. 不要忽略 Python 依赖管理工具差异

## Stop Conditions

1. 找不到实际 ASGI 入口
2. 项目依赖额外服务但文档不明

## Output Hints

1. `activeSkills` 应包含 `ecosystem.fastapi`
2. `risks` 应记录 ASGI 入口不清、额外依赖不明等问题
3. `reasoningSummary` 可明确 FastAPI / Uvicorn 证据来源

## Related Skills

1. `artifact.web-service`
2. `entrypoint.existing-dockerfile`
3. `environment.linux`
