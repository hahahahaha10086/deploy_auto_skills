---
name: guard.no-desktop-auto-deploy
description: 风险约束 Skill。用于阻止桌面应用、GUI 程序和平台强依赖的原生项目进入默认自动部署路径，避免错误容器化和站点化。
category: guard
version: 1.0.0
---

# Skill: guard.no-desktop-auto-deploy

## Purpose

防止桌面程序或 GUI 项目被错误自动部署。

## Trigger Signals

1. 已命中桌面应用、GUI 程序或强平台依赖证据
2. 项目存在桌面打包、安装包或 GUI 运行说明
3. Agent 准备进入默认 Web 部署或容器化路径

## Required Evidence

1. README 中对桌面交付物的描述
2. GUI 框架、桌面资源或安装配置
3. 是否缺少稳定 HTTP 服务入口
4. 是否依赖桌面环境、系统集成或图形界面

## Analysis Steps

1. 先确认项目核心交付物是不是桌面程序
2. 再判断是否只是具备网络能力，而非真正服务型系统
3. 若桌面证据强于服务证据，则阻断默认自动部署路径

## Decision Hints

若项目被识别为桌面应用或强 GUI 依赖：

1. 不进入默认 Web 部署流程
2. 不自动生成 HTTP 服务型部署产物
3. 优先转人工确认或构建型交付路径

## Risk Guards

1. 桌面程序往往依赖图形界面和平台能力
2. 把桌面程序容器化通常不是用户真实目标

## Stop Conditions

1. GUI 交付物为项目核心
2. 文档明确说明是桌面程序

## Output Hints

1. `blockedActions` 应包含默认 Web 部署和服务化动作
2. `requiresManualReview` 应提高
3. `reasoningSummary` 应明确记录桌面交付物证据

## Related Skills

1. `artifact.desktop-app`
2. `build.cmake`
3. `playbooks.deployment-decision`
