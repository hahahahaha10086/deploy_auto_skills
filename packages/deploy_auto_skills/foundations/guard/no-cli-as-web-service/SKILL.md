---
name: guard.no-cli-as-web-service
description: 风险约束 Skill。用于阻止 Agent 把 CLI 工具误判成 Web 服务，防止错误进入 HTTP 部署、端口探活和站点验证流程。
category: guard
version: 1.0.0
---

# Skill: guard.no-cli-as-web-service

## Purpose

防止 CLI 工具项目被错误地走 Web 服务部署流程。

## Trigger Signals

1. README 主入口是命令参数、命令示例或一次性执行命令
2. 仓库缺少稳定端口、站点、API 服务入口
3. 项目主要输出是二进制、脚本工具或命令行行为
4. 同时出现“容器化”线索但缺少服务化线索

## Required Evidence

1. README 中的主要使用方式
2. 可执行命令、帮助输出或示例参数
3. 是否存在监听端口、HTTP 路由、站点配置
4. 是否存在长期运行服务的正式入口

## Analysis Steps

1. 先判断项目的主要交互方式是不是命令执行
2. 再判断是否存在稳定的 HTTP 服务入口
3. 区分“可以放进容器运行”和“应作为 Web 服务部署”
4. 若 CLI 证据强于服务证据，则激活该 guard

## Decision Hints

当 CLI 证据强于服务证据时：

1. 不要生成站点型部署方案
2. 不要默认设置 HTTP 健康检查
3. 不要把帮助命令或单次执行命令当作服务启动命令

## Risk Guards

1. 很多工具项目可运行，但并不属于“部署项目”
2. 容器化工具不等于 Web 服务化

## Stop Conditions

1. 项目主要交互方式是命令参数
2. 文档没有任何稳定服务入口

## Output Hints

1. `blockedActions` 应包含 Web 服务化相关动作
2. `requiresManualReview` 可在 CLI 与服务证据冲突时提升
3. `reasoningSummary` 应明确说明“CLI 证据强于服务证据”

## Related Skills

1. `artifact.cli-tool`
2. `artifact.web-service`
3. `guard.no-desktop-auto-deploy`
