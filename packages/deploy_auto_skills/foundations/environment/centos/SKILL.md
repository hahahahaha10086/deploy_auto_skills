---
name: environment.centos
description: 用于识别目标部署环境为 CentOS 或兼容系发行版，并指导 Agent 评估 yum/dnf、systemd、SELinux 与官方部署方式的兼容性。
category: environment
version: 1.0.0
---

# Skill: environment.centos

## Purpose

帮助 Agent 在目标环境为 CentOS 或其兼容系发行版时，识别与 Ubuntu 路径不同的系统依赖与服务管理约束。

## Trigger Signals

1. 用户明确指定目标环境是 CentOS
2. 执行环境或宿主机为 CentOS / Rocky / AlmaLinux 一类
3. 项目文档中明确出现 `yum`、`dnf`、SELinux、systemd

## Required Evidence

1. 用户指定的目标发行版和版本
2. README 中对应发行版的安装说明
3. 是否依赖 `yum` / `dnf`
4. 是否涉及 SELinux、firewalld、systemd

## Analysis Steps

1. 先确认项目是否提供面向 CentOS 的官方说明
2. 再判断关键依赖是否依赖 `yum` / `dnf`
3. 检查项目是否可能受 SELinux、系统防火墙或旧版本系统库影响
4. 若项目只提供 Ubuntu 路径，则提高风险等级

## Decision Hints

1. CentOS 路径不应被 Ubuntu 默认逻辑覆盖
2. 若官方没有 CentOS 说明，应谨慎自动化
3. 若项目依赖 Docker、Compose、systemd，要额外确认系统兼容性

## Risk Guards

1. 不要将 `apt` 路径直接迁移到 CentOS
2. 不要忽略 SELinux 与防火墙带来的运行差异
3. 不要忽略旧版系统库与新项目构建链的不兼容问题

## Stop Conditions

1. 项目文档无 CentOS 路径且环境适配证据不足
2. 关键依赖在当前发行版上不可得或版本过旧
3. 安全策略可能阻止部署，但没有明确处理方案

## Output Hints

1. `targetEnvironment` 应为 `centos` 或兼容系发行版
2. `distributionVersion` 应记录明确版本或未知状态
3. `environmentRisks` 应记录 `yum/dnf`、SELinux、防火墙或旧库兼容性风险

## Related Skills

1. `environment.linux`
2. `entrypoint.readme`
3. `guard.reuse-official-config-first`
