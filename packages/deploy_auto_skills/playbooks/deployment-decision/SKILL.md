---
name: playbooks.deployment-decision
description: 部署决策作战手册。用于指导主 Agent 在项目理解完成后，如何排序候选入口、何时复用官方配置、何时允许兜底生成，以及如何形成最终执行决策。
category: playbook
version: 1.0.0
---

# Skill: playbooks.deployment-decision

## Purpose

这是主 Agent 在“项目理解完成之后”使用的部署决策流程。

## Trigger Signals

1. 项目理解阶段已基本完成
2. 已经形成候选入口列表
3. 需要从多个策略中选择最终部署路径

## Required Evidence

进入本手册前，应已经具备：

1. 交付物类型识别
2. 架构类型识别
3. 官方入口扫描
4. 构建链识别
5. 风险约束加载
6. 环境与权限事实

## Analysis Steps

推荐按以下顺序做最终部署决策：

0. **首先确认意图**：厘清用户的核心诉求是“生产级上线 (production deployment)”还是“本地快速跑起来看效果 (local quick run)”。
1. 是否存在官方 Compose
2. 是否存在官方 Dockerfile
3. 是否存在 Makefile / Script / README 明确部署步骤
4. 是否允许自动执行
5. 是否允许生成兜底产物

## Decision Hints

推荐部署策略优先级：

1. `reuse_existing_compose`
2. `reuse_existing_dockerfile`
3. `reuse_makefile_or_script`
4. `reuse_documented_manual_flow`
5. `generate_fallback_artifacts`
6. `manual_review_only`

决策规则：

0. **意图分流**：如果用户诉求仅仅是“本地运行/看一眼效果”，应当立刻放宽对“生产级托管方案（如打包 Nginx）”的强求。
   - **注意**：如果在 Windows 系统下遇到巨型前端 Monorepo 文件系统 IO 问题，千万**不要**采用 Docker 代码全量挂载的形式去尝试绕过 Node 版本不一致。
   - 面对环境前卫而项目依赖老旧（如 node-sass 或旧式 Rush 配置），首选寻找相应的环境变量豁免配置（如 `RUSH_ALLOW_UNSUPPORTED_NODEJS=1`）退回宿主机执行，最后才考虑无挂载的轻 Docker 策略。
1. 发现官方 Compose 时，默认终止通用生成路径
2. 发现官方 Dockerfile 时，默认优先复用其构建逻辑
3. 若 README / Script / Makefile 提供完整流程，应优先复用
4. 只有当现成入口不存在或不可用时，才允许兜底生成
5. 桌面程序、CLI、框架仓库默认提高人工复核优先级

## Risk Guards

1. 不要因为“能生成”就选择生成
2. 不要把生成能力当默认主路径
3. 不要忽略系统级依赖、数据库、外部模型和存储依赖
4. 不要只看工具存在，不看权限是否可执行
5. **警惕“生产环境原教旨主义”**：不要为了教条的“正规部署”而忽视真正的效率。但在使用 Docker 解决问题时，必须防范 Windows 下虚拟挂载巨型工程带来的灾难性 IO 瓶颈。
6. **网络与基建兜底**：在独立纯净的容器/沙箱中执行包管理命令时，务必主动注入合适的依赖镜像源。
7. **Monorepo 构建定律**：运行子包服务 (dev) 前，必须保证它的兄弟前置依赖子包已经完成构建 (build)。
8. **子进程环境穿透**：注意多进程打包工具会让 PowerShell 行内临时环境变量丢失，应首选生成 `.env` 落盘持久化或使用 `cross-env`。

## Stop Conditions

1. 入口候选冲突且无法排序
2. 关键环境变量或依赖来源不明
3. 自动部署风险高于收益
4. Probe 显示推荐入口实际上不可执行

## Output Hints

主 Agent 应至少输出：

1. `recommendedStrategy`
2. `selectedEntrypoint`
3. `executionScope`
4. `allowGeneratedArtifacts`
5. `requiresManualReview`
6. `blockedActions`
7. `reasoningSummary`

## Related Skills

1. `playbooks.project-understanding`
2. `entrypoint.existing-compose`
3. `guard.reuse-official-config-first`
4. `guard.windows-docker-io`
5. `guard.monorepo-build-first`
6. `guard.env-persistence`
7. `guard.network-mirror`
