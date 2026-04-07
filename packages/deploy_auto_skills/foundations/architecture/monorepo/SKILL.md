---
name: architecture.monorepo
description: 用于识别 monorepo、多包、多应用仓库，帮助 Agent 避免把根目录误当成唯一运行入口。适用于 apps/packages、workspace、rush、turbo、nx 等结构。
category: architecture
version: 1.0.0
---

# Skill: architecture.monorepo

## Purpose

帮助 Agent 识别 monorepo，并定位真正的可运行子项目。

## Trigger Signals

1. 存在 `apps/`、`packages/`、`services/`、`modules/`
2. 存在 `pnpm-workspace.yaml`、`rush.json`、`turbo.json`、`nx.json`
3. 根目录不是最终应用，而是聚合工程

## Required Evidence

1. monorepo 管理文件，如 `pnpm-workspace.yaml`、`rush.json`、`turbo.json`、`nx.json`
2. 工作区目录，如 `apps/`、`packages/`
3. README 中关于多应用、多包工程的说明
4. 每个候选 app 的独立入口和构建线索

## Analysis Steps

1. 先识别 monorepo 管理工具
2. 再找可运行 app
3. 再找该 app 的独立部署入口
4. 判断根目录配置是否只是聚合层
5. 识别候选 app 之间的优先级和依赖关系

## Decision Hints

1. 不要默认在根目录安装或启动
2. 先定位目标 app，再决定构建和运行方式
3. 若仓库自带编排文件，优先使用编排文件

## Risk Guards

1. 根目录 `package.json` 可能只是工作区配置
2. 错误的根目录安装命令会导致构建失败或误判

## Stop Conditions

1. 无法定位真正的应用入口
2. 多个子项目都可能是候选，但缺乏优先级证据

## Output Hints

1. `architectureType` 应包含 `monorepo`
2. `risks` 应记录根目录误装、目标 app 不明确等问题
3. `blockedActions` 可包含根目录默认安装或启动动作

## Related Skills

1. `build.pnpm-workspace`
2. `guard.no-root-install-in-monorepo`
3. `entrypoint.existing-compose`
