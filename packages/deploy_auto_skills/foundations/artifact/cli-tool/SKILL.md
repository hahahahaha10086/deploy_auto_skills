---
name: artifact.cli-tool
description: 用于识别命令行工具型项目，帮助 Agent 避免把 CLI 工具误判成 Web 服务。适用于存在单文件入口、命令帮助、参数说明、控制台示例等场景。
category: artifact
version: 1.0.0
---

# Skill: artifact.cli-tool

## Purpose

帮助 Agent 识别 CLI 工具，并阻止错误进入 Web 部署主流程。

## Trigger Signals

1. README 主要内容是命令行参数和使用示例
2. 项目入口表现为 `tool.py`、`main.go`、`cmd/`、`bin/` 或单文件主程序
3. 文档重点是 `-h`、`--help`、`usage`、命令参数，而不是服务访问地址

## Required Evidence

1. README 中的命令示例、帮助输出和参数说明
2. 入口目录或主程序，如 `cmd/`、`bin/`、单文件主程序
3. 是否缺少稳定端口、站点或长期运行服务线索
4. 是否存在更强的 Web 服务或桌面程序证据

## Analysis Steps

1. 先看 README 是否以命令示例为主
2. 再看是否存在长期运行的服务进程
3. 再判断是否仅属于本地工具运行
4. 区分“可被容器封装的工具”和“应被部署为服务的系统”

## Decision Hints

1. 若项目核心交互方式是命令行，优先归类为 CLI 工具
2. CLI 工具默认不进入 Web 服务部署主路径
3. 若需要容器化，也应作为“工具镜像”而不是“站点部署”

## Risk Guards

1. 不要把 `python xxx.py` 误判成 Web 服务启动
2. 不要把安全工具、运维工具、扫描工具误判为后台服务

## Stop Conditions

1. 项目没有长期运行服务的明确信号
2. 项目验证方式明显是命令执行结果而不是服务可达性

## Output Hints

1. `artifactType` 应倾向 `cli-tool`
2. `blockedActions` 应包含默认 Web 服务化动作
3. `risks` 应记录与 Web 服务证据冲突的部分

## Related Skills

1. `guard.no-cli-as-web-service`
2. `artifact.web-service`
3. `playbooks.deployment-decision`
