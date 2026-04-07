---
name: guard.env-persistence
description: 多层子进程嵌套场景下持久化传递环境变量，防止并发脚本导致变量脱落。
category: guard
version: 1.0.0
---

# Skill: guard.env-persistence

## Context & Alert

在前端和 Node.js 生态中（尤其是使用 `vite`, `concurrently`, `rushx` 等脚本时），工具链内部经常会创建衍生子进程甚至子 shell。在 Windows (PowerShell / CMD) 环境下，通过形如 `$env:RUSH_ALLOW_UNSUPPORTED_NODEJS=1; node foo` 或单纯的会话内临时定义手段，环境变量的作用域并不能安全、可靠地穿透这些包裹工具引发的并发执行或深层子进程栈。这会导致诸如“明明配了变量，但启动时并发工具链里的检查仍在报错”的诡异现象。

## Enforcement Rules

1. **废弃单行隐蔽赋值**：严禁过度依赖 PowerShell 行内临时环境变量赋值来试图穿越含有 `concurrently` / `lerna` / `rushx` 等指令的深度命令栈。
2. **优先 .env 落盘法**：为了让 Node.js 环境及深层子孙进程安全存续并保证正确装载环境变量，应该主动把那些“开关/豁免类”配置直接写到项目或者组件下的 `.env`（或 `.env.local` 等）文件内，交给工具栈的 dotenv 原生加载机制去解决，确保穿透。
3. **使用跨平台工具显式注入**：如果不具备使用文本缓存的条件，应当使用 `cross-env` 等 Node 跨平台工具库通过进程命令自身进行显式传递，例如修改指令为 `cross-env VAR=1 command...`。
