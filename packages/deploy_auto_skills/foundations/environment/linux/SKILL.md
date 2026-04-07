---
name: environment.linux
description: 用于识别目标部署环境为 Linux，并指导 Agent 判断 shell、服务管理、容器运行与系统依赖的兼容性。
category: environment
version: 1.0.0
---

# Skill: environment.linux

## Purpose

帮助 Agent 在目标环境为 Linux 时正确理解常见的 bash、systemd、容器、守护进程和系统依赖前提。

## Trigger Signals

1. 用户明确指定目标环境是 Linux
2. 执行器、宿主机或部署目标为 Linux 服务器
3. 项目文档主要以 shell 命令、systemd、Docker、包管理器为主

## Required Evidence

1. 用户指定的目标系统类型
2. 当前执行器类型
3. README 中的安装与启动方式
4. 是否存在 `.sh`、`systemd`、Docker、Compose 相关说明

## Analysis Steps

1. 先确认目标是否是 Linux 服务器或 Linux 容器主机
2. 再确认仓库官方是否偏向 Linux-first 部署
3. 检查入口是否依赖系统级服务、包管理器或 root 权限
4. 若还存在发行版差异，再交给更具体的环境 Skill 细化

## Decision Hints

1. Linux 可作为多数服务型项目的默认宿主假设，但不能忽略具体发行版差异
2. 若项目官方提供 shell / Compose / systemd 路径，应优先按官方方式评估
3. 不要因为目标是 Linux 就跳过 Ubuntu / CentOS 差异判断

## Risk Guards

1. 不要把 Linux 视为单一环境
2. 不要忽略包管理器、服务管理器和权限差异
3. 不要默认所有 Linux 环境都预装 Docker、Compose、build-essential

## Stop Conditions

1. 项目入口强依赖特定发行版，但当前目标发行版未知
2. 关键系统依赖无法确认是否存在
3. 项目运行方式与目标 Linux 宿主管理策略冲突明显

## Output Hints

1. `targetEnvironment` 应倾向 `linux`
2. `distributionHints` 应提示是否需要进一步细化到 Ubuntu / CentOS
3. `environmentRisks` 应记录发行版未知、权限未知或系统依赖未知等风险

## Related Skills

1. `environment.ubuntu`
2. `environment.centos`
3. `entrypoint.existing-compose`
