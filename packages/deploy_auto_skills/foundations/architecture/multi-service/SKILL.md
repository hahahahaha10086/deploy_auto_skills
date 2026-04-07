---
name: architecture.multi-service
description: 用于识别多服务项目结构，帮助 Agent 发现前后端分离、网关+工作进程、agent+server、多个可运行角色等情况，避免退化成根目录单服务部署。
category: architecture
version: 1.0.0
---

# Skill: architecture.multi-service

## Purpose

帮助 Agent 识别多服务架构，并优先寻找官方编排入口。

## Trigger Signals

1. 仓库中同时出现多个服务目录
2. 文档中描述多个角色、多个进程、多个容器
3. 存在 Compose、编排脚本或服务依赖关系

## Required Evidence

1. 多个服务目录，如 `frontend`、`backend`、`gateway`、`worker`、`agent`、`server`
2. 编排文件，如 `docker-compose.yml`、`docker-compose.yaml`
3. README / docs 中关于多个角色、多个容器、依赖关系的描述
4. 每个运行单元的启动线索与依赖信息

## Analysis Steps

1. 先找编排文件
2. 再识别服务角色
3. 再确认主入口和依赖关系
4. 判断根目录是否只是聚合层而不是实际运行单元
5. 识别哪些服务必须一起验证，哪些只是辅助角色

## Decision Hints

1. 多服务项目优先使用 Compose 或等价编排方式
2. 不要直接生成单服务 Dockerfile 作为主方案
3. 不要默认根目录代表可运行单元

## Risk Guards

1. 根目录包管理器不一定代表真实运行单元
2. 单个端口探活不足以验证整个系统

## Stop Conditions

1. 服务依赖关系不清楚
2. 找不到主入口且缺少文档

## Output Hints

1. `architectureType` 应包含 `multi-service`
2. `entrypointCandidates` 应优先体现编排入口
3. `risks` 应记录服务依赖不清、根目录不可运行等问题

## Related Skills

1. `artifact.web-service`
2. `entrypoint.existing-compose`
3. `guard.reuse-official-config-first`
