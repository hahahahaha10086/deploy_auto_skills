---
name: environment.ubuntu
description: 用于识别目标部署环境为 Ubuntu，并指导 Agent 评估 apt、systemd、bash、Docker 与官方安装说明的兼容性。
category: environment
version: 1.0.0
---

# Skill: environment.ubuntu

## Purpose

帮助 Agent 在目标环境为 Ubuntu 时，优先复用项目中面向 Ubuntu 的官方安装与部署说明。

## Trigger Signals

1. 用户明确指定目标环境是 Ubuntu
2. README、脚本或文档中明确出现 Ubuntu
3. 官方安装步骤以 `apt`、`systemd`、bash 为主

## Required Evidence

1. 用户指定的 Ubuntu 版本或大版本范围
2. README 中 Ubuntu 相关段落
3. 是否依赖 `apt`、`systemctl`、`bash`
4. 是否存在与 CentOS / Alpine 等环境分开的安装说明

## Analysis Steps

1. 先确认项目是否有专门面向 Ubuntu 的说明
2. 再确认关键依赖是否通过 `apt` 安装
3. 检查入口是否依赖 systemd、bash、Docker、Compose
4. 如果官方文档就是以 Ubuntu 为主，优先按该路径做策略判断

## Decision Hints

1. Ubuntu 适合作为 Linux 服务型项目的高优先级部署目标
2. 若项目 README 以 Ubuntu 为默认环境，可提高官方文档权重
3. 若文档中的命令明显面向 Ubuntu，应避免被 Windows 或其它发行版逻辑覆盖

## Risk Guards

1. 不要把 Ubuntu 路径直接等价于所有 Linux 发行版
2. 不要忽略不同 Ubuntu 版本的软件包差异
3. 不要忽略 root / sudo 前提

## Stop Conditions

1. 项目要求特定 Ubuntu 版本，但当前环境版本未知
2. 核心依赖在 Ubuntu 上需要额外仓库或外部安装源
3. 关键安装步骤无法在当前权限模型下完成

## Output Hints

1. `targetEnvironment` 应为 `ubuntu`
2. `distributionVersion` 应记录明确版本或未知状态
3. `environmentCompatibility` 应反映与官方 Ubuntu 路径的兼容程度

## Related Skills

1. `environment.linux`
2. `entrypoint.readme`
3. `entrypoint.script`
