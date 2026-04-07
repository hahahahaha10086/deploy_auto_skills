---
name: guard.no-root-install-in-monorepo
description: 风险约束 Skill。用于阻止 Agent 在 monorepo 或多包工程中直接使用根目录进行安装和构建，避免错误命中根 package manager。
category: guard
version: 1.0.0
---

# Skill: guard.no-root-install-in-monorepo

## Purpose

防止 Agent 在 monorepo 中错误地把根目录当作最终可运行应用。

## Trigger Signals

1. 已命中 `architecture.monorepo` 或 workspace 相关证据
2. 根目录存在聚合配置但目标 app 尚未明确
3. Agent 准备在根目录执行安装或构建

## Required Evidence

1. monorepo / workspace 管理文件
2. 候选 app 目录与独立入口
3. 根目录脚本和锁文件的真实作用
4. 是否存在官方编排入口或明确子项目路径

## Analysis Steps

1. 先确认仓库是否属于 monorepo 或 workspace
2. 再定位真正的目标 app 或官方入口
3. 判断根目录命令是否只是聚合任务而非实际构建入口
4. 若目标 app 未定位，则阻断根目录安装和构建

## Decision Hints

当存在 monorepo 或 workspace 证据时：

1. 不要默认在根目录执行安装
2. 不要默认在根目录执行构建
3. 必须先定位目标 app 或官方编排入口

## Risk Guards

1. 根目录往往只是聚合工程
2. 根目录锁文件和脚本不一定适用于实际部署单元

## Stop Conditions

1. 目标 app 未定位
2. workspace 结构不明确

## Output Hints

1. `blockedActions` 应包含根目录默认安装和构建动作
2. `risks` 应记录目标 app 未定位或 workspace 结构不清
3. `reasoningSummary` 应显式记录目标 app 路径或缺失原因

## Related Skills

1. `architecture.monorepo`
2. `build.pnpm-workspace`
3. `playbooks.deployment-decision`
