---
name: playbooks.failure-correction
description: 失败纠偏作战手册。用于指导 Shadow Agent 或主 Agent 在部署失败后，如何判断是入口选错、架构误判、构建链错误，还是环境问题，并据此纠偏。
category: playbook
version: 1.0.0
---

# Skill: playbooks.failure-correction

## Purpose

帮助 Agent 在部署失败后快速判断：

1. 是执行失败
2. 还是理解失败
3. 还是入口选择失败
4. 还是构建链误用

## Trigger Signals

1. 部署流程已经失败
2. Executor 已返回失败阶段、日志摘要或健康检查失败
3. 主 Agent 或 Shadow Agent 需要决定是否重试、切换入口或转人工复核

## Required Evidence

1. `buildStatus`、`runStatus`、`healthcheckStatus`
2. `failureStage` 与执行日志摘要
3. 当前选中的入口、构建链与激活 Skill
4. 仓库中的官方入口、架构线索与环境事实

## Analysis Steps

失败后建议按以下顺序检查：

1. 是否选错交付物类型
2. 是否选错架构类型
3. 是否忽略了官方入口
4. 是否使用了错误的包管理器或构建系统
5. 是否遗漏环境变量、外部依赖或数据库
6. 是否属于执行层面的暂时故障

## Decision Hints

常见纠偏路径：

### 路径 1：错过官方 Compose

现象：

1. 生成的 Dockerfile 构建失败
2. 仓库其实存在 Compose 或多服务编排文件

纠偏：

1. 回到入口扫描阶段
2. 激活 `entrypoint.existing-compose`
3. 阻止继续走单服务生成路径

### 路径 2：根目录误装

现象：

1. `npm install` / `pnpm install` / `mvn package` 在根目录失败
2. 仓库实际是 monorepo 或多模块工程

纠偏：

1. 回到架构识别阶段
2. 激活 `architecture.monorepo`
3. 激活 `guard.no-root-install-in-monorepo`

### 路径 3：CLI 被当成服务

现象：

1. 启动命令立即退出
2. 健康检查永远失败
3. README 其实主要是命令行用法

纠偏：

1. 重新识别交付物类型
2. 激活 `artifact.cli-tool`
3. 移除 HTTP 部署假设

### 路径 4：桌面程序被当成服务

现象：

1. CMake 构建或 GUI 依赖与服务部署路径冲突
2. 容器化后没有实际使用价值

纠偏：

1. 激活 `artifact.desktop-app`
2. 激活 `guard.no-desktop-auto-deploy`
3. 转入人工复核或构建产物路径

### 路径 5：环境权限不足

现象：

1. 服务启动命令无报错，但 daemon 访问被拒绝
2. 健康检查可达，但日志提示权限错误
3. 文件写入失败或端口绑定失败

纠偏：

1. 要求用户重新运行 `foundation.env-probe` 脚本获取最新 Probe 结果
2. 检查 `permissions.canAccessDockerDaemon`、`permissions.canWriteWorkspace`、`compatibilityHints`
3. 根据 Probe 结果调整部署方案（降权运行 / 切换路径 / 提示用户修复权限）
4. 不要重复同一条无权限路径

## Risk Guards

1. 不要在失败后立刻重复同一条错误路径
2. 不要把执行故障误判成项目理解错误
3. 不要因为一次失败就跳过官方入口复核

## Stop Conditions

1. 缺少足够日志和失败证据
2. 多条候选纠偏路径冲突且无法排序
3. 连纠偏方向都无法判断时，应转人工复核

## Output Hints

建议输出：

1. `failureCategory`
2. `wrongAssumption`
3. `correctionAction`
4. `shouldRetry`
5. `requiresManualReview`
6. `reasoningSummary`

## Related Skills

Shadow Agent 在纠偏时至少要检查：

1. 主 Agent 是否忽略官方入口
2. 主 Agent 是否误判项目类型
3. 主 Agent 是否误用根目录
4. 主 Agent 是否过早生成兜底产物
5. 主 Agent 是否漏掉关键外部依赖

常见相关 Skill：

1. `playbooks.project-understanding`
2. `playbooks.deployment-decision`
3. `guard.reuse-official-config-first`
