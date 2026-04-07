---
name: guard.windows-docker-io
description: 全局风险守卫：警惕在 Windows/WSL2 环境下使用 Docker 源码挂载机制处理海量文件（如前端巨型 Monorepo），以防止出现极端的 IO 性能瓶颈。
category: guard
version: 1.0.0
---

# Skill: guard.windows-docker-io

## Description

在 Windows 系统下（不管是依赖 WSL2 还是 Hyper-V 后端），Docker 的 Volume Bind Mount（`-v .:/app`）会穿过虚拟缓存层（VirtioFS 等）。如果你试图将一个包含数万个（甚至几十万个）细碎文件的仓库（典型如 `node_modules` 满天飞的巨型前端 Monorepo）完整挂载进容器并执行需要全盘扫描的命令（如 `git hash-object`、全量重新构建等），将会引发灾难级的 IO 阻塞，原本几秒钟的任务会被拉长到几十分钟甚至卡死。

## Trigger Signals

当主 Agent 试图在一个探测为 `environment.windows` 的主机上，推荐使用基于 Docker 源码全量挂载的容器化开发或编译方案，且项目特征满足 `architecture.monorepo` 时，必须触发本守卫。

## Execution Rules

1. **优先寻求原生降维**：如果容器化的仅仅是为了避开某个环境依赖版本冲突（如 Node.js 版本不对），优先寻找目标工具包的内置逃生舱口（例如 Rush 的 `$env:RUSH_ALLOW_UNSUPPORTED_NODEJS=1`），或建议使用 NVM/Conda 切换局部原生 Node 环境，**坚决不要仅仅为了版本隔离就顺手将巨型仓库丢进 Windows Docker 里。**
2. **规避全盘哈希拦截**：如果非要在 Windows Docker 环境下编译，坚决禁用触发全库扫描的功能（例如必须绕过 Rush 的文件指纹哈希，或必须提前做好 `.dockerignore` 不挂载不需要的节点）。
3. **只挂载产物**：如果必须使用 Docker 作为最终服务寄宿容器，强烈建议先在 Windows 宿主机原生完成 `build` 动作生成 `dist/`，随后仅把必须的运行时产物目录和代码挂载进去运行服务，**不要把重度的底层编译任务放进跨系统挂载盘中。**

## Conflict Rules

本守卫与 `playbooks.deployment-decision` 中提及的“使用Docker降维化解依赖”并不冲突。本守卫仅反对在 **“Windows + 海量小文件源码挂载 + 高密集 IO 编译任务”** 这一特定恶劣组合下滥用 Docker。如果是正常的单体 Python 项目或后端编译型语言（带完整的依赖黑名单屏蔽），Docker 依然是首选。
