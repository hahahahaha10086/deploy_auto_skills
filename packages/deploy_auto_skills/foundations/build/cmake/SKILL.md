---
name: build.cmake
description: 用于识别 CMake 原生工程，帮助 Agent 把项目归类为编译型或桌面型交付物，并避免误走容器服务主路径。
category: build
version: 1.0.0
---

# Skill: build.cmake

## Purpose

帮助 Agent 识别 CMake 驱动的原生项目。

## Trigger Signals

1. 存在 `CMakeLists.txt`
2. 存在 `CMakePresets.json`
3. README 或 BUILD 文档中使用 `cmake`

## Required Evidence

1. `CMakeLists.txt`、`CMakePresets.json`
2. README / BUILD 文档中的 `cmake` 命令
3. 目标类型线索，如二进制、桌面程序、服务或库
4. Probe 中关于 `cmake`、编译器、平台能力的事实

## Analysis Steps

1. 先看 README / BUILD 文档
2. 再看 CMake 配置和 target
3. 再判断交付物是二进制、桌面程序还是服务
4. 确认是否依赖特定平台、图形界面或系统集成
5. 区分“可构建”与“可自动部署为服务”

## Decision Hints

1. 默认视为构建型项目，而不是直接 Web 服务
2. 需要结合 artifact skill 判断是否是桌面程序或原生服务
3. 没有额外证据时，不自动生成容器部署方案

## Risk Guards

1. 不要因为项目有网络功能就自动当作 Web 服务
2. 不要把 CMake 项目简化成单容器 HTTP 服务

## Stop Conditions

1. 平台依赖强烈
2. 图形界面或系统集成明显

## Output Hints

1. `activeSkills` 应包含 `build.cmake`
2. `risks` 应记录平台依赖、GUI 依赖或系统集成风险
3. `requiresManualReview` 可在交付物类型不清时提升

## Related Skills

1. `artifact.desktop-app`
2. `environment.windows`
3. `playbooks.deployment-decision`
