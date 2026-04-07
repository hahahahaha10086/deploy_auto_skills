---
name: environment.wsl
description: 用于识别目标部署环境为 WSL，并指导 Agent 处理 Windows 与 Linux 混合路径、端口映射、Docker 集成和宿主差异。
category: environment
version: 1.0.0
---

# Skill: environment.wsl

## Purpose

帮助 Agent 在目标环境为 WSL 时识别路径、网络、文件系统和 Docker 集成上的混合风险。

## Trigger Signals

1. 用户明确指定目标环境是 WSL
2. 当前执行器或宿主标识为 WSL
3. 部署流程同时涉及 Windows 路径和 Linux 命令

## Required Evidence

1. 当前执行环境是否为 WSL
2. Docker 是否由 Windows 侧提供
3. 仓库路径是否位于 Windows 文件系统挂载路径
4. 项目是否依赖本地端口、文件监听、路径映射

## Analysis Steps

1. 先确认当前执行环境是否真的是 WSL
2. 再判断项目是否适合在混合环境下运行
3. 检查 Docker、端口、文件路径是否跨 Windows / Linux 边界
4. 若存在大量路径映射与文件监听依赖，提高风险等级

## Decision Hints

1. WSL 不是纯 Linux，也不是纯 Windows
2. 若项目支持 Docker，需判断 Docker 是由 WSL 还是 Windows 侧承载
3. 若路径和日志位置跨系统边界，主 Agent 应显式记录

## Risk Guards

1. 不要混用 Windows 路径和 Linux 路径而不做转换
2. 不要忽略 Docker Desktop 与 WSL 集成的行为差异
3. 不要忽略文件监听、权限和端口转发在 WSL 下的额外问题

## Stop Conditions

1. 路径映射规则不清晰
2. Docker 集成方式不清晰
3. 关键依赖要求纯 Linux 或纯 Windows，而当前仅有 WSL

## Output Hints

1. `targetEnvironment` 应为 `wsl`
2. `environmentCompatibility` 应体现混合环境可执行性
3. `environmentRisks` 应记录跨系统路径、Docker 集成和文件监听风险

## Related Skills

1. `environment.windows`
2. `environment.linux`
3. `entrypoint.existing-compose`
