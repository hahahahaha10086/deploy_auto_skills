---
name: build.pnpm-workspace
description: 用于识别 pnpm workspace / 多包前端工程，帮助 Agent 避免误用 npm、避免在根目录错误安装依赖，并优先按工作区规则定位真正应用。
category: build
version: 1.0.0
---

# Skill: build.pnpm-workspace

## Purpose

帮助 Agent 正确处理 `pnpm` 和 workspace 结构。

## Trigger Signals

1. 存在 `pnpm-lock.yaml`
2. 存在 `pnpm-workspace.yaml`
3. 存在前端或多包工程目录结构

## Required Evidence

1. `pnpm-lock.yaml`、`pnpm-workspace.yaml`
2. `package.json` 中的 `packageManager: pnpm@...`
3. `apps/`、`packages/` 等工作区目录
4. README / Dockerfile 中是否明确使用 `pnpm`

## Analysis Steps

1. 先确认是否是单包还是 workspace
2. 再确认目标 app 所在目录
3. 再确认是否已有官方 Dockerfile 或构建方式
4. 识别根目录 `package.json` 是否只是聚合配置
5. 确认安装、构建和启动命令是否应在子目录执行

## Decision Hints

1. 存在 pnpm 证据时，不要默认使用 npm
2. 存在 workspace 证据时，不要默认根目录可直接构建
3. 若仓库自带 Dockerfile，优先复用其包管理流程

## Risk Guards

1. `npm install` 可能导致锁文件体系错误
2. 根目录 `package.json` 可能不代表真实 app

## Stop Conditions

1. 无法确认目标 app 路径
2. 工作区结构复杂但缺乏文档

## Output Hints

1. `activeSkills` 应包含 `build.pnpm-workspace`
2. `blockedActions` 可包含错误的根目录 `npm install`
3. `risks` 应记录目标 app 不明确或 workspace 结构复杂的情况

## Related Skills

1. `architecture.monorepo`
2. `guard.no-root-install-in-monorepo`
3. `entrypoint.existing-dockerfile`
