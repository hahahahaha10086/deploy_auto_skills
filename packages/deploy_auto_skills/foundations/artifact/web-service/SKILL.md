---
name: artifact.web-service
description: 用于识别“可作为服务运行并可进行部署验证”的 Web 项目。适用于存在 HTTP 接口、前后端站点、API 服务、容器服务等场景，帮助 Agent 判断项目是否属于 Web 服务交付物，而不是 CLI、桌面程序或纯库。
category: artifact
version: 1.0.0
---

# Skill: artifact.web-service

## Purpose

帮助 Agent 判断一个仓库是否属于可部署的 Web 服务或 Web 平台。

## Trigger Signals

1. 仓库中存在 `Dockerfile`、`docker-compose`、Web 框架目录或明显的服务入口
2. README 中存在 `localhost`、`port`、`http://`、`API`、`dashboard`、`web`、`frontend` 等线索
3. 存在 `package.json`、`pyproject.toml`、`pom.xml`、`go.mod` 等服务型工程文件

## Required Evidence

1. 服务入口目录，如 `frontend`、`backend`、`server`、`api`
2. 官方部署入口，如 `Dockerfile`、`docker-compose.yml`、`docker-compose.yaml`
3. README 中关于端口、访问地址、服务启动的说明
4. 代码或配置中的 HTTP、站点或 API 线索

## Analysis Steps

1. 先看是否存在官方部署入口
2. 再看 README 中是否有服务访问地址或端口说明
3. 再定位主要运行单元和健康检查线索
4. 排除 CLI、桌面程序、框架仓库和纯库的更强证据
5. 若命中 Web 服务，再继续判断是单服务还是多服务

## Decision Hints

1. 若项目可通过 HTTP 提供功能，优先归类为 Web 服务
2. 若同时存在多个运行单元，不要退化成单服务假设
3. 归类为 Web 服务后，仍需继续判断是单服务还是多服务

## Risk Guards

1. 不要因为存在 `package.json` 就直接认定为可部署站点
2. 不要把前端框架仓库误判成完整可部署系统

## Stop Conditions

1. 看不到稳定运行入口
2. 看不到任何服务访问或启动证据

## Output Hints

1. `artifactType` 应倾向 `web-service`
2. `risks` 应记录“只是前端框架”或“缺少稳定服务入口”等不确定性
3. `requiresManualReview` 可在 Web 与 CLI / desktop 证据冲突时提升

## Related Skills

1. `architecture.multi-service`
2. `entrypoint.existing-compose`
3. `guard.no-cli-as-web-service`
