---
name: ecosystem.nextjs
description: 用于补充 Next.js 项目的识别、运行入口、部署边界和常见风险。适用于 Next.js 站点、前端应用和前后端混合前端壳场景。
category: ecosystem
version: 1.0.0
---

# Skill: ecosystem.nextjs

## Purpose

帮助 Agent 正确理解 Next.js 项目，不把它简单当成普通 Node 服务。

## Trigger Signals

1. 依赖中出现 `next`
2. 存在 `next.config.js`、`next.config.ts`
3. README 明确提到 Next.js

## Required Evidence

1. `next.config.js`、`next.config.ts`
2. 依赖中的 `next`
3. `package.json` 中的 `next dev`、`next build`、`next start`
4. 工作区结构、Dockerfile 和系统级编排入口

## Analysis Steps

1. 先看它是独立前端还是更大系统中的一个子应用
2. 再看是否已有官方 Dockerfile
3. 再看包管理器和工作区结构

## Decision Hints

1. Next.js 只是生态标识，不代表整个仓库就是完整可部署产品
2. 若仓库是多服务系统中的前端，优先使用系统级编排方案
3. 若有现成 Dockerfile，应优先复用

## Risk Guards

1. 不要把 Next.js 前端仓库自动当成完整后端系统
2. 不要忽略 `pnpm`、workspace 或 monorepo 结构

## Stop Conditions

1. 无法确认该 Next.js 应用在整体系统中的角色
2. 只找到前端壳，没有后端上下文

## Output Hints

1. `activeSkills` 应包含 `ecosystem.nextjs`
2. `risks` 应记录“只是前端壳”或系统角色不明问题
3. `reasoningSummary` 可明确 Next.js 在整体系统中的角色判断

## Related Skills

1. `artifact.web-service`
2. `build.pnpm-workspace`
3. `architecture.monorepo`
