---
name: playbooks.project-understanding
description: 项目理解作战手册。用于指导主 Agent 在面对陌生仓库时，如何按固定顺序读取证据、组合 Skills、形成项目理解报告，并为后续部署决策打基础。
category: playbook
version: 1.0.0
---

# Skill: playbooks.project-understanding

## Purpose

这是主 Agent 的通用项目理解流程。

## Trigger Signals

1. 主 Agent 需要对陌生仓库进行首次理解
2. 还未形成稳定的项目理解报告
3. 还未明确交付物类型、架构与入口

## Required Evidence

1. 顶层目录结构
2. `docker/`、`deploy/`、`ops/`、`infra/` 等目录
3. README / Install / docs 中的部署段落
4. Compose、Dockerfile、Makefile、脚本
5. 锁文件、包管理器、构建系统文件
6. Probe 输出的环境、工具与权限事实

## Analysis Steps

按以下固定顺序执行，每步激活对应 Skill，不跳步，不乱序：

### Step 0：确认 Probe 事实存在
- 若已有 Probe 输出数据 → 直接继续
- 若且你（Agent）具备终端执行能力，且目标机器就是当前环境 → 请**自行静默执行** `.agents/skills/foundations/env-probe/scripts/run-probes.ps1` 脚本，抓取结果后继续。
- 若你无法执行命令，或目标是远端机器 → **停止分析**，把启动脚本的命令发给用户，要求用户执行并提供结果后再继续。

### Step 1：读文件树，不先下结论
- 不允许在看完文件树之前就判断项目类型
- 记录顶层目录、关键配置文件、锁文件

### Step 2：识别交付物类型（激活对应 artifact skill）
- 有 HTTP 接口 / 稳定服务入口证据 → 激活 `artifact.web-service`
- README 主入口是命令参数 / 一次性执行 → 激活 `artifact.cli-tool` + **必须同时激活** `guard.no-cli-as-web-service`
- 存在 GUI 框架 / 桌面打包说明 → 激活 `artifact.desktop-app` + **必须同时激活** `guard.no-desktop-auto-deploy`
- 以上证据均弱 → 暂不归类，继续收集证据

### Step 3：识别架构类型（激活对应 architecture skill）
- 存在 `apps/`、`packages/` 或 workspace 文件 → 激活 `architecture.monorepo` + **必须同时激活** `guard.no-root-install-in-monorepo`
- 存在多个服务目录 / 编排文件 / 多角色描述 → 激活 `architecture.multi-service`
- 两者可以同时激活，不互斥

### Step 4：识别官方部署入口（按优先级顺序激活 entrypoint skill）
优先级从高到低，**发现高优先级后仍要继续扫描，但决策权交给更高优先级**：

1. 存在 Compose 文件 → 激活 `entrypoint.existing-compose`（最高优先级）
2. 存在 Dockerfile → 激活 `entrypoint.existing-dockerfile`
3. 存在 Makefile 且被 README 引用 → 激活 `entrypoint.makefile`
4. 存在部署脚本 → 激活 `entrypoint.script`
5. README 有完整部署段落 → 激活 `entrypoint.readme`
6. 以上均不充分，存在 CI workflow → 激活 `entrypoint.ci-workflow`（最低优先级）

### Step 5：识别构建链
- 存在 `pnpm-lock.yaml` / `pnpm-workspace.yaml` → 激活 `build.pnpm-workspace`
- 存在 `CMakeLists.txt` → 激活 `build.cmake`
- 存在 `pom.xml` / `build.gradle` → 记录为 Maven / Gradle（暂无独立 skill）

### Step 6：识别生态类型（激活对应 ecosystem skill）
- 存在 FastAPI 信号 → 激活 `ecosystem.fastapi`
- 存在 LangGraph 信号 → 激活 `ecosystem.langgraph`
- 存在 Next.js 信号 → 激活 `ecosystem.nextjs`
- 存在 PHP 单体信号 → 激活 `ecosystem.php-monolith`
- 存在 Spring 信号 → 激活 `ecosystem.spring`

### Step 7：激活全局守卫
- 无论何时，**必须**激活 `guard.reuse-official-config-first`

### Step 8：读取 Probe 事实，对照激活结论做兼容性校验
- 若 `tools.docker = false` → 不能依赖容器化入口
- 若 `permissions.canAccessDockerDaemon = false` → 标记权限风险
- 若 Probe 结果与已激活入口不兼容 → 重新排序候选入口

### Step 9：识别目标环境（激活对应 environment skill）
- 激活顺序：大类 → 子类（先激活 `environment.linux`，再激活 `environment.ubuntu` 或 `environment.centos`）
- WSL 单独处理，激活 `environment.wsl`

### Step 10：形成结构化项目理解报告
- 输出所有激活的 Skill 列表（`activeSkills`）
- 输出候选入口（`entrypointCandidates`）及其优先级
- 输出风险（`risks`）和阻断动作（`blockedActions`）

## Decision Hints

主 Agent 至少要回答这些问题：

1. 这是什么类型的交付物
2. 是单服务还是多服务
3. 是否是 monorepo
4. 是否已有官方部署入口
5. 主要运行单元在哪里
6. 是否允许自动部署
7. 是否需要人工确认

## Risk Guards

1. 不要仅凭语言决定部署方式
2. 不要在证据不足时进入生成路径
3. 不要忽略仓库自带部署知识
4. 不要只看仓库，不看 Probe 输出

## Stop Conditions

1. 项目类型不清晰
2. 官方入口不清晰且兜底风险高
3. 交付物与用户目标不匹配
4. 环境事实与候选入口明显不兼容

## Output Hints

建议输出以下结构化字段：

1. `artifactType`
2. `architectureType`
3. `entrypointCandidates`
4. `targetEnvironment`
5. `environmentCompatibility`
6. `activeSkills`
7. `recommendedStrategy`
8. `allowGeneratedArtifacts`
9. `requiresManualReview`
10. `risks`
11. `reasoningSummary`

## Related Skills

1. `artifact.web-service`
2. `architecture.multi-service`
3. `entrypoint.existing-compose`
4. `guard.reuse-official-config-first`
