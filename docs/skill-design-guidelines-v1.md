# Skill Design Guidelines v1

> 文档版本：v1.0
> 创建时间：2026-04-03
> 适用范围：面向复杂、异构、非标准 GitHub 项目的 AI 部署分析与决策系统
> 目标：定义 skill 在复杂部署场景中的职责边界、设计原则、分类方式、数据结构与和 agent 的协作模式

---

## 1. 背景

真实世界里的项目并不整齐。

常见情况包括：

1. 根目录没有可直接运行的入口
2. `docker-compose.yaml` 放在 `docker/`、`deploy/`、`ops/` 等子目录
3. 同时存在 `frontend`、`backend`、`worker`、`agent`、`server` 等多个运行单元
4. 项目是 CLI、桌面程序、框架、库、原生编译项目，而不是 Web 服务
5. 项目自带 Dockerfile、Makefile、脚本或 README 部署步骤，但并不在默认位置
6. 根目录的语言标识与真正的部署入口不一致
7. Monorepo、workspace、多模块工程不能按根目录单服务方式处理

因此，系统不能把 skill 设计成“部署模板集合”，也不能把 skill 理解为某个 Dockerfile 片段。

在这个系统里：

**skill 不是部署文件，而是帮助 AI 理解项目、发现部署线索、做出正确决策的能力单元。**

---

## 2. 设计目标

这份文档希望解决 5 个问题：

1. skill 在复杂部署场景中到底负责什么
2. skill 不应该负责什么
3. skill 应该按什么维度分类
4. skill 以什么结构保存，便于 agent 消费
5. 主 agent 和辅助 agent 应如何与 skill 协作

---

## 3. 核心原则

### 3.1 Skill 是认知能力，不是部署产物

skill 的职责是：

1. 识别项目特征
2. 指导 AI 按正确顺序阅读仓库
3. 帮助 AI 发现现成部署入口
4. 提醒 AI 避免常见误判
5. 给出决策提示与停止条件

skill 的职责不包括：

1. 充当固定 Dockerfile 模板
2. 直接写死某种构建命令
3. 对所有同类项目输出统一部署产物
4. 越过仓库已有部署文件强行替换

### 3.2 先理解项目，再决定怎么部署

系统不应从“写 Dockerfile”开始，而应从“这是什么项目”开始。

建议固定先回答这些问题：

1. 这是 Web 服务、CLI、桌面应用、框架、库还是构建型项目
2. 它是单服务、多服务、monorepo、前后端分离还是插件式结构
3. 仓库是否已经提供官方部署入口
4. 应优先复用什么入口
5. 是否允许自动部署
6. 是否必须人工确认

### 3.3 优先复用仓库已有知识

在复杂场景里，仓库作者已经写好的内容通常比 AI 推断更可靠。

优先级建议如下：

1. 仓库自带 Compose / Dockerfile / Helm / 安装脚本 / Makefile
2. README / Install / docs 中的明确部署步骤
3. CI workflow 中的构建与启动信号
4. AI 基于结构化证据做出的兜底推断

### 3.4 Skill 面向特征，而不是面向具体项目名

不应设计：

1. `deer-flow-skill`
2. `ffmpeg-skill`
3. `sqlmap-skill`

应设计：

1. `artifact.cli-tool`
2. `architecture.multi-service`
3. `entrypoint.existing-compose`
4. `pkgmgr.pnpm-workspace`
5. `guard.no-cli-as-web-service`

### 3.5 Skill 必须可组合

复杂项目无法依赖单一 skill 完成判断。

一个项目可能同时命中：

1. `artifact.web-service`
2. `architecture.multi-service`
3. `entrypoint.existing-compose`
4. `pkgmgr.pnpm-workspace`
5. `guard.no-root-install-in-monorepo`

主 agent 应该根据 skill 组合来形成部署判断。

---

## 4. Skill 的职责边界

### 4.1 Skill 负责什么

建议 skill 负责以下 6 类事情：

1. 解释仓库结构
2. 识别部署入口
3. 识别交付物类型
4. 补充生态经验
5. 标注风险和停止条件
6. 指导验证方式

### 4.2 Skill 不负责什么

建议明确禁止 skill 承担以下职责：

1. 输出固定 Dockerfile 文本
2. 输出固定 `docker-compose.yaml` 文本
3. 把某个语言直接映射成唯一部署方案
4. 在未识别官方部署入口前就给出构建命令
5. 绕过主 agent 独立决定部署执行方式

### 4.3 Dockerfile / Compose 的正确位置

如果仓库已经提供官方 Dockerfile / Compose：

1. skill 应该帮助 AI 发现并复用它们
2. 主 agent 应优先采用它们
3. 生成器不应覆盖它们

如果仓库没有提供官方部署文件：

1. 主 agent 在证据充分时可以进入兜底生成路径
2. 兜底生成属于执行阶段策略，不属于 skill 本体

---

## 5. Skill 分类体系

建议采用“多维分类 + 组合判定”的方式。

### 5.1 交付物类型维度

回答：这是什么类型的项目。

建议分类：

1. `artifact.web-service`
2. `artifact.multi-service-platform`
3. `artifact.cli-tool`
4. `artifact.desktop-app`
5. `artifact.framework-library`
6. `artifact.build-only-project`

### 5.2 架构维度

回答：项目结构是什么。

建议分类：

1. `architecture.single-service`
2. `architecture.multi-service`
3. `architecture.monorepo`
4. `architecture.frontend-backend-split`
5. `architecture.server-client`
6. `architecture.agent-server`
7. `architecture.plugin-based`

### 5.3 部署入口维度

回答：应优先从哪里开始。

建议分类：

1. `entrypoint.existing-compose`
2. `entrypoint.existing-dockerfile`
3. `entrypoint.makefile`
4. `entrypoint.script`
5. `entrypoint.readme`
6. `entrypoint.ci-workflow`

### 5.4 语言与运行时维度

回答：主要语言和运行时形态是什么。

建议分类：

1. `runtime.python`
2. `runtime.nodejs`
3. `runtime.java`
4. `runtime.go`
5. `runtime.php`
6. `runtime.cpp-c`
7. `runtime.mixed`

### 5.5 构建与包管理维度

回答：不要用错构建链和安装命令。

建议分类：

1. `build.npm`
2. `build.pnpm`
3. `build.yarn`
4. `build.mvn`
5. `build.gradle`
6. `build.make`
7. `build.cmake`
8. `build.configure`
9. `build.uv`
10. `build.poetry`

### 5.6 生态增强维度

回答：遇到具体生态时需要补什么认知。

建议分类：

1. `ecosystem.nextjs`
2. `ecosystem.fastapi`
3. `ecosystem.django`
4. `ecosystem.express`
5. `ecosystem.spring`
6. `ecosystem.langgraph`
7. `ecosystem.php-monolith`
8. `ecosystem.rush-monorepo`
9. `ecosystem.pnpm-workspace`

### 5.7 约束与纠偏维度

回答：哪些错误必须提前拦住。

建议分类：

1. `guard.reuse-official-config-first`
2. `guard.no-root-install-in-monorepo`
3. `guard.no-cli-as-web-service`
4. `guard.no-desktop-auto-deploy`
5. `guard.no-framework-as-product`
6. `guard.require-manual-review-when-entrypoint-unclear`

---

## 6. Skill 结构设计

建议 skill 保存为结构化文件，由主 agent 统一读取。

### 6.1 最小字段建议

```yaml
id: architecture.multi-service
name: Multi-Service Architecture
version: 1.0.0
category: architecture
intent: detect multi-service project topology
match_signals:
  directories_any:
    - frontend
    - backend
    - worker
    - server
    - agent
  files_any:
    - docker-compose.yml
    - docker-compose.yaml
    - compose.yml
    - compose.yaml
analysis_steps:
  - inspect deployment directories first
  - inspect compose files before generating artifacts
  - detect service roles from folder names and README
decision_hints:
  prefer_existing_entrypoint: true
  avoid_single_service_fallback: true
risk_flags:
  - root package manager may not represent runnable service
  - multiple runtimes may require staged startup
stop_conditions:
  - no clear primary entrypoint and no official deployment doc
verification_hints:
  - verify all declared services, not only first HTTP port
```

### 6.2 字段说明

建议每个 skill 包含这些字段：

1. `id`
   唯一标识

2. `name`
   可读名称

3. `version`
   版本号

4. `category`
   所属维度，例如 `artifact`、`architecture`、`entrypoint`、`guard`

5. `intent`
   这个 skill 想帮助 AI 判断什么

6. `match_signals`
   命中线索，来自文件树、README、脚本、配置文件、目录结构、依赖等

7. `analysis_steps`
   命中后 AI 应继续检查什么

8. `decision_hints`
   对主 agent 的决策建议

9. `risk_flags`
   常见误判点

10. `stop_conditions`
    什么情况下不应继续自动部署

11. `verification_hints`
    成功后应该如何验证

### 6.3 不建议放入 skill 的字段

以下内容不建议直接进入 skill：

1. 整份 Dockerfile 文本
2. 整份 compose 模板
3. 某语言唯一固定的安装命令
4. 某语言唯一固定的启动命令
5. 一组不带证据来源的硬编码部署结果

---

## 7. Skill 与 Agent 的协作模式

### 7.1 角色划分

建议将系统至少拆成以下 4 个协作阶段：

1. `Scout`
   负责收集证据，不下部署结论

2. `Main Agent`
   负责组合 skill、形成部署决策、选择执行路径

3. `Shadow Agent`
   负责纠偏、找反例、阻止错误自动化

4. `Executor`
   只负责执行，不再做自由推断

### 7.2 Scout 的职责

Scout 负责输出结构化证据包。

建议包含：

1. 顶层目录结构
2. 部署相关目录，如 `docker/`、`deploy/`、`ops/`、`infra/`
3. 关键文件位置，如 Compose、Dockerfile、Makefile、脚本
4. README / Install / docs 中与部署相关的片段
5. 构建和包管理信息
6. 多服务和 monorepo 线索

### 7.3 Main Agent 的职责

Main Agent 负责：

1. 根据 Scout 证据激活匹配到的 skill
2. 汇总 skill 输出的事实和约束
3. 形成部署判断
4. 决定是否自动执行
5. 决定是否复用已有部署入口
6. 决定是否允许兜底生成

### 7.4 Shadow Agent 的职责

Shadow Agent 负责从反方向审查主 agent。

重点检查：

1. 是否忽略了仓库已有 Compose / Dockerfile / Makefile / 脚本
2. 是否把 CLI、桌面程序、框架、库误判成 Web 服务
3. 是否在 monorepo 中错误使用根目录作为构建入口
4. 是否在入口不清楚时过早进入生成路径
5. 是否在耗时过长或不确定性过高时应该转人工确认

### 7.5 Executor 的职责

Executor 不参与项目理解，只消费决策结果。

它只负责：

1. build
2. start
3. healthcheck
4. log collection
5. stop / cleanup

---

## 8. 推荐工作流

建议整体工作流如下：

1. Scout 扫描仓库并生成证据包
2. Main Agent 激活匹配到的基础 skill 和约束 skill
3. Main Agent 输出项目理解报告
4. Shadow Agent 审查项目理解报告
5. Main Agent 形成最终部署策略
6. Executor 按策略执行
7. 验证器根据 skill 提示执行健康检查和结果确认

其中最关键的是：

**生成 Dockerfile / Compose 只能是最后兜底步骤，不能作为默认主路径。**

---

## 9. 结构化输出建议

建议 Main Agent 在理解阶段统一输出如下结构：

```json
{
  "artifactType": "multi-service-platform",
  "architectureType": "frontend-backend-split",
  "entrypointCandidates": [
    {
      "type": "existing-compose",
      "path": "docker/docker-compose.yaml",
      "priority": 100
    },
    {
      "type": "readme",
      "path": "README.md",
      "priority": 60
    }
  ],
  "activeSkills": [
    "artifact.multi-service-platform",
    "architecture.multi-service",
    "entrypoint.existing-compose",
    "runtime.mixed",
    "build.pnpm",
    "guard.reuse-official-config-first"
  ],
  "recommendedStrategy": "reuse_existing_compose",
  "allowGeneratedArtifacts": false,
  "requiresManualReview": false,
  "risks": [
    "multiple runtimes detected",
    "root directory is not guaranteed runnable"
  ]
}
```

这个输出不是最终执行命令，而是给后续部署决策用的中间协议。

---

## 10. 第一版落地建议

建议不要一开始就做很多具体 skill，而是先落地这三样：

### 10.1 先做 taxonomy

先固定 skill 顶层分类：

1. `artifact`
2. `architecture`
3. `entrypoint`
4. `runtime`
5. `build`
6. `ecosystem`
7. `guard`

### 10.2 先做 schema

先把 skill 的字段格式定下来，让 agent 能稳定读取。

### 10.3 先做最小可用 skill 集

第一批建议只做这些：

1. `artifact.web-service`
2. `artifact.cli-tool`
3. `artifact.desktop-app`
4. `architecture.multi-service`
5. `architecture.monorepo`
6. `entrypoint.existing-compose`
7. `entrypoint.script`
8. `entrypoint.makefile`
9. `build.pnpm`
10. `build.cmake`
11. `guard.reuse-official-config-first`
12. `guard.no-root-install-in-monorepo`
13. `guard.no-cli-as-web-service`
14. `guard.no-desktop-auto-deploy`

---

## 11. 最终结论

在复杂部署场景里，skill 的正确定位是：

**帮助 AI 理解项目、发现入口、规避误判、形成决策。**

不是：

1. Dockerfile 模板
2. Compose 模板
3. 固定命令模板

系统真正的主线应是：

`仓库 -> 证据 -> skill 组合 -> agent 决策 -> 执行`

而不是：

`仓库 -> 找一个 skill -> 直接生成部署文件`

如果后续继续扩展，这份文档建议作为：

1. skill taxonomy 设计基线
2. 主 agent 与辅助 agent 的协作基线
3. 部署入口优先级和风险约束基线

