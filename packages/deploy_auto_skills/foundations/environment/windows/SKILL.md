---
name: environment.windows
description: 用于识别目标部署环境为 Windows，并约束命令风格、路径形式、脚本选择和运行方式。
category: environment
version: 1.0.0
---

# Skill: environment.windows

## Purpose

帮助 Agent 在目标环境为 Windows 时调整部署判断，避免直接套用 Linux/Unix 风格命令与路径假设。

## Trigger Signals

1. 用户明确指定目标环境是 Windows
2. 执行器、宿主机或部署目标显示为 Windows
3. 部署流程要求使用 PowerShell、Docker Desktop 或本机 GUI 运行

## Required Evidence

1. 用户指定的目标环境
2. 当前执行器类型
3. 项目 README 中是否明确写明仅支持 Linux / bash
4. 项目是否依赖 `.sh`、`systemd`、`apt`、`yum`

## Analysis Steps

1. 先确认目标环境是不是 Windows 本机
2. 再确认项目是适合容器运行、命令行运行还是桌面运行
3. 检查项目入口是否强依赖 bash、systemd 或 Linux 特性
4. 若仓库本身更偏 Linux-first，则提高人工复核优先级

## Decision Hints

1. 不要默认使用 bash 命令作为主入口
2. 不要默认使用 Linux 路径风格
3. 若仓库已有 Docker 入口，可优先考虑 Windows + Docker Desktop 路径
4. 若项目是桌面程序，应评估是否更适合原生 Windows 运行

## Risk Guards

1. 不要直接假设 `.sh` 在目标环境里可运行
2. 不要直接假设 `chmod +x`、`systemctl`、`apt` 可用
3. 不要把 Linux-only 说明当成 Windows 可直接执行方案

## Stop Conditions

1. 官方部署说明明确只支持 Linux，且没有 Windows 替代路径
2. 关键入口完全依赖 Linux shell 或 systemd
3. 当前目标环境与项目官方支持环境冲突明显

## Output Hints

1. `targetEnvironment` 应为 `windows`
2. `environmentCompatibility` 应表达与当前入口的兼容程度
3. `environmentRisks` 应记录 bash、systemd、Linux-only 依赖等风险

## Related Skills

1. `entrypoint.script`
2. `entrypoint.readme`
3. `guard.no-desktop-auto-deploy`
