# Skill 系统规范 v2

> 文档版本：v2.0
> 创建时间：2026-04-03
> 适用范围：面向下一代 AI-First 部署系统的 Markdown Skill 体系
> 目标：定义一套与旧版 YAML Skill 明确分离的全新 Skill v2 方案，包括文件格式、目录结构、职责边界与 Agent 协作方式

---

## 1. 为什么需要 v2

当前 v1 Skill 模型离“部署模板系统”太近了。

典型问题有：

1. 容易让人把 Skill 理解成固定部署配方
2. YAML 结构容易逐渐演变成硬编码构建命令和运行命令
3. 不适合承载长篇推理、反例、阅读顺序、风险说明和决策提示
4. 很容易把 Skill 做成 Dockerfile 生成器，而不是项目理解能力

因此，v2 需要做一次明确切换：

1. Skill 不是部署产物
2. Skill 不是 Dockerfile 模板
3. Skill 是给 AI Agent 使用的推理辅助文档
4. Skill 应该更像“可读、可审阅、可演进的知识文档”，而不是纯配置块

基于这个目标，v2 采用 Markdown 作为主要 Skill 文件格式。

---

## 2. 核心定位

在 v2 中：

**Skill 是一份 Markdown 文档，用来教 AI Agent 如何识别某种项目局面、优先看哪些证据、避免哪些误判，以及下一步该如何做部署决策。**

一个 v2 Skill 应该帮助 Agent 回答这些问题：

1. 这是什么类型的项目
2. 这个项目是否适合自动部署
3. 官方或最可信的部署入口在哪里
4. 哪些文件和目录应该优先检查
5. 哪些兜底路径允许使用
6. 哪些动作必须被拦截

一个 v2 Skill 不应该直接是：

1. Dockerfile
2. Compose 模板
3. Shell 脚本
4. 固定的安装命令清单
5. 一套对所有项目通用的硬编码部署方案

---

## 3. 与 v1 的隔离原则

v2 不应该在原地覆盖或改写旧版 Skill 系统。

建议规则如下：

1. 保留 v1，作为旧版兼容层
2. 单独创建新的 v2 根目录
3. 不要把 `.yaml` 和 `.md` Skill 定义混放在同一棵目录树里
4. 让 Agent 在加载时显式区分：当前使用的是 v1 还是 v2

建议命名如下：

1. 旧版系统：`backend/skillpacks/`
2. v2 系统：`skills-v2/`

这样做的好处是：

1. 迁移安全
2. 避免加载器歧义
3. 避免旧逻辑和新逻辑互相污染

---

## 4. 推荐的 v2 目录结构

```text
skills-v2/
├── README.md
├── registry/
│   ├── catalog.md
│   └── loading-rules.md
├── foundations/
│   ├── artifact/
│   │   ├── web-service/
│   │   │   └── SKILL.md
│   │   ├── cli-tool/
│   │   │   └── SKILL.md
│   │   ├── desktop-app/
│   │   │   └── SKILL.md
│   │   └── framework-library/
│   │       └── SKILL.md
│   ├── architecture/
│   │   ├── single-service/
│   │   │   └── SKILL.md
│   │   ├── multi-service/
│   │   │   └── SKILL.md
│   │   ├── monorepo/
│   │   │   └── SKILL.md
│   │   └── frontend-backend-split/
│   │       └── SKILL.md
│   ├── entrypoint/
│   │   ├── existing-compose/
│   │   │   └── SKILL.md
│   │   ├── existing-dockerfile/
│   │   │   └── SKILL.md
│   │   ├── makefile/
│   │   │   └── SKILL.md
│   │   ├── script/
│   │   │   └── SKILL.md
│   │   └── readme/
│   │       └── SKILL.md
│   ├── build/
│   │   ├── pnpm-workspace/
│   │   │   └── SKILL.md
│   │   ├── cmake/
│   │   │   └── SKILL.md
│   │   ├── make/
│   │   │   └── SKILL.md
│   │   └── uv-python/
│   │       └── SKILL.md
│   └── guard/
│       ├── reuse-official-config-first/
│       │   └── SKILL.md
│       ├── no-root-install-in-monorepo/
│       │   └── SKILL.md
│       ├── no-cli-as-web-service/
│       │   └── SKILL.md
│       └── no-desktop-auto-deploy/
│           └── SKILL.md
├── ecosystems/
│   ├── nextjs/
│   │   └── SKILL.md
│   ├── fastapi/
│   │   └── SKILL.md
│   ├── spring/
│   │   └── SKILL.md
│   ├── langgraph/
│   │   └── SKILL.md
│   └── php-monolith/
│       └── SKILL.md
└── playbooks/
    ├── project-understanding/
    │   └── SKILL.md
    ├── deployment-decision/
    │   └── SKILL.md
    └── failure-correction/
        └── SKILL.md
```

---

## 5. 为什么使用 Markdown

Markdown 更适合做 v2 Skill 的默认格式，因为 Skill 需要的远不止几个字段。

Skill 需要承载：

1. 意图说明
2. 示例
3. 反例
4. 阅读顺序
5. 对 Agent 的操作指引
6. 停止条件
7. 风险说明
8. 兜底策略

这些内容用 Markdown 表达、审阅、维护和迭代，都会比 YAML 更自然。

同时，Markdown 也更适合被 Agent 当作“知识文档”来阅读，而不是单纯配置对象。

---

## 6. 一个 v2 Skill 应包含什么

每个 `SKILL.md` 都应该是一份结构稳定的 Markdown 文档。

建议包含这些章节：

1. `Purpose`
2. `When To Use`
3. `When Not To Use`
4. `Signals`
5. `Inspection Order`
6. `Decision Rules`
7. `Risk Guards`
8. `Stop Conditions`
9. `Verification Hints`
10. `Examples`

### 6.1 最小推荐模板

```md
# Skill: architecture.multi-service

## Purpose
Help the agent recognize projects that contain multiple runnable services or roles.

## When To Use
- The repository contains multiple top-level app directories such as `frontend`, `backend`, `worker`, `agent`, `server`.
- The repository contains compose files or deployment directories.
- The README describes multiple services, roles, or startup processes.

## When Not To Use
- The repository is clearly a single binary, CLI, or single-process web app.

## Signals
- Directories: `frontend`, `backend`, `worker`, `server`, `agent`
- Files: `docker-compose.yml`, `docker-compose.yaml`, `compose.yml`, `compose.yaml`
- README keywords: `services`, `gateway`, `worker`, `agent`, `console`

## Inspection Order
1. Check deployment directories first.
2. Check compose files before generating anything.
3. Identify service roles from folder names and README.
4. Confirm whether one service depends on others.

## Decision Rules
- Prefer an existing compose or orchestrated startup path over single-service fallback.
- Do not assume the repository root is the runnable unit.
- If multiple service roles are present, require service-by-service verification.

## Risk Guards
- Root package manager may not represent the actual deployable unit.
- A single HTTP port may not be enough to validate success.

## Stop Conditions
- No clear primary entrypoint and no official deployment guide.
- Service dependency graph is unclear.

## Verification Hints
- Verify each declared service separately.
- Check health or readiness for all critical roles.

## Examples
- Frontend + backend + gateway + worker
- Agent + server + console
```

---

## 7. Markdown 中的 Skill 元数据

虽然 v2 使用 Markdown，但我们仍然需要稳定的机器可读元数据。

建议做法：

1. 在文档顶部使用一个很小的 frontmatter
2. frontmatter 尽量保持最小化
3. 真正的推理内容放在普通 Markdown 章节中

示例：

```md
---
id: architecture.multi-service
version: 2.0.0
category: architecture
priority: 80
status: active
---

# Skill: architecture.multi-service
...
```

这样可以同时获得两种好处：

1. 机器可读的身份标识
2. 人类和 Agent 都易读的推理内容

如果团队坚持完全不要 frontmatter，也可以，但那就必须额外维护一份独立的 registry 索引。

---

## 8. v2 Skill 中不应该出现什么

为了避免重蹈 v1 的问题，v2 Skill 不应该包含：

1. 完整 Dockerfile 模板
2. 完整 Compose 模板
3. 硬编码的通用安装命令
4. 硬编码的通用启动命令
5. 会覆盖仓库原生部署文件的产物内容

允许包含的内容是：

1. 如何识别正确的构建系统
2. 应该先看哪些文件
3. 如何识别官方部署入口
4. 什么情况下允许进入兜底生成路径

---

## 9. Agent 应如何使用 v2 Skill

### 9.1 主 Agent

主 Agent 应使用 v2 Skill 来完成这些任务：

1. 识别项目类型
2. 给证据排序
3. 选择部署路径
4. 拦截不安全的兜底行为
5. 决定是自动执行还是只进入人工复核

### 9.2 Shadow Agent

Shadow Agent 应该用 v2 Skill 来反向审查主 Agent。

它需要重点追问：

1. 主 Agent 是否忽略了官方部署入口
2. 主 Agent 是否把 CLI 或桌面程序误判成 Web 服务
3. 主 Agent 是否错误假设根目录可运行
4. 主 Agent 是否在发现仓库原生部署文件之前就进入了生成路径

### 9.3 Executor

Executor 不应该直接解释 Skill。

它只应消费主 Agent 在 Skill 评估之后产出的结构化部署决策。

---

## 10. 推荐的 v2 加载模型

建议加载顺序：

1. 先加载 foundation skills
2. 再加载 ecosystem skills
3. 再加载 guard skills
4. 最后加载 playbook skills

建议解析优先级：

1. `guard` 可以约束其他所有类别
2. `entrypoint` 的操作优先级高于 `runtime` 和 `build`
3. `architecture` 应先于兜底部署规划被解决
4. `artifact` 应先于任何“默认 Web 部署”假设被解决

---

## 11. 第一批推荐的 v2 Skill

第一批 Skill 应该尽量少而关键。

建议如下：

1. `artifact.web-service`
2. `artifact.cli-tool`
3. `artifact.desktop-app`
4. `architecture.multi-service`
5. `architecture.monorepo`
6. `entrypoint.existing-compose`
7. `entrypoint.script`
8. `entrypoint.makefile`
9. `build.pnpm-workspace`
10. `build.cmake`
11. `guard.reuse-official-config-first`
12. `guard.no-root-install-in-monorepo`
13. `guard.no-cli-as-web-service`
14. `guard.no-desktop-auto-deploy`
15. `playbooks.project-understanding`

---

## 12. 迁移建议

建议迁移路径如下：

1. 保留 v1，确保兼容性
2. 为 `skills-v2/` 单独建设一套并行加载器
3. 优先把 v2 用在“项目理解”阶段
4. 不要把部署产物生成逻辑迁移进 v2 Skill
5. 先让 v2 负责指导决策，再去影响执行
6. 只有当主 Agent 可以稳定依赖 v2 Skill 做推理时，才考虑逐步淡出 v1

---

## 13. 最终立场

v2 Skill 系统应当是：

1. 文档优先
2. 推理优先
3. Agent 优先

它的目的不是：

1. 生成 Dockerfile
2. 替代仓库原生部署知识
3. 编码一套通用命令模板

它的真正目的应该是：

1. 帮助 Agent 理解陌生仓库
2. 帮助 Agent 选择正确部署路径
3. 帮助 Agent 避免高频误判
4. 为杂乱的真实项目建立一层稳定的知识体系
