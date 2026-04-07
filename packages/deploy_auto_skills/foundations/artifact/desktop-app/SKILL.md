---
name: artifact.desktop-app
description: 用于识别桌面应用和原生 GUI 项目，帮助 Agent 避免把桌面程序误判成容器化 Web 服务。适用于 CMake、Qt、Win32、Electron GUI、桌面打包等场景。
category: artifact
version: 1.0.0
---

# Skill: artifact.desktop-app

## Purpose

帮助 Agent 识别桌面应用，并将其从默认自动部署路径中排除。

## Trigger Signals

1. README 明确说明是 Windows、macOS、Linux 桌面应用
2. 项目包含 GUI 框架、桌面打包说明或桌面截图
3. 存在 `CMakeLists.txt`、桌面资源目录、安装包说明、GUI 入口

## Required Evidence

1. README 中对桌面交付物的描述
2. GUI 框架、桌面打包或安装配置
3. 桌面资源目录，如 `res/`、`ui/`
4. 是否缺少稳定 HTTP 服务入口

## Analysis Steps

1. 先看 README 对交付物的描述
2. 再看构建系统和平台说明
3. 最后判断是否需要人工确认
4. 排除“只是前端站点”或“只是服务端 API”的更强证据

## Decision Hints

1. 桌面应用默认不走自动 Web 部署
2. 若只提供二进制或安装包，归类为构建型交付物
3. 若仓库只是源码，不应强行生成容器部署方案

## Risk Guards

1. 不要因为存在网络功能就误判成 Web 服务
2. 不要把 CMake 原生项目默认容器化

## Stop Conditions

1. 项目核心交付物是 GUI 程序
2. 项目依赖桌面环境、图形界面或系统集成

## Output Hints

1. `artifactType` 应倾向 `desktop-app`
2. `blockedActions` 应包含默认 Web 服务化或自动部署动作
3. `requiresManualReview` 可默认提高

## Related Skills

1. `build.cmake`
2. `environment.windows`
3. `guard.no-desktop-auto-deploy`
