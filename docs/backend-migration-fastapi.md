# 后端迁移方案：Node.js -> Python FastAPI

> 文档版本：v1.3
> 创建时间：2026-04-02
> 最后更新：2026-04-02
> 状态：**可执行草案，待确认后开工**

---

## 1. 目标与边界

当前后端位于 `src/`，使用 Node.js 原生 HTTP 服务，核心问题是：

| 问题 | 现状 |
|---|---|
| 数据持久化薄弱 | 任务和技能数据依赖内存 + JSON 文件，缺少事务与可靠恢复 |
| 长任务可靠性不足 | 任务流水线在进程重启后无法自动恢复 |
| 数据演进成本高 | 无 ORM、无迁移工具，字段变更依赖手工兼容 |
| AI / Docker 集成扩展受限 | Python 生态更适合后续 AI 能力与数据处理演进 |

迁移目标：

1. 用 `FastAPI + SQLAlchemy + Alembic` 替换现有 Node.js 后端。
2. 在前端尽量不改代码的前提下，保持现有 API 契约稳定。
3. 先完成“能力对等迁移”，再处理“可靠性增强”。

本次迁移不包含：

1. 前端界面改版。
2. 任务流水线的产品逻辑重构。
3. 将所有特殊项目一次性支持完毕，仍然按 skill 渐进扩展。

---

## 2. 当前后端事实基线

以下内容基于当前代码而不是口头假设：

### 2.1 服务入口

- 入口文件：`src/server.js`
- 默认端口：`3333`
- 健康检查：`GET /health`
- 响应格式统一为：

```json
{ "success": true, "data": {}, "error": null }
```

或

```json
{ "success": false, "data": null, "error": { "code": "X", "message": "..." } }
```

### 2.2 当前路由面

当前所有业务路由集中在 `src/routes/tasks.js`，实际已暴露的接口包括：

| 分类 | 路由 |
|---|---|
| 健康检查 | `GET /health` |
| 任务 | `POST /api/tasks` |
| 任务批量创建 | `POST /api/tasks/batch` |
| 任务列表 | `GET /api/tasks` |
| 任务详情 | `GET /api/tasks/:taskId` |
| 任务删除 | `DELETE /api/tasks/:taskId` |
| 任务重试 | `POST /api/tasks/:taskId/retry` |
| 任务策略 | `GET /api/tasks/:taskId/ai/strategy` |
| 任务诊断 | `GET /api/tasks/:taskId/ai/diagnosis` |
| 任务日志 | `GET /api/tasks/:taskId/logs` |
| 任务时间线 | `GET /api/tasks/:taskId/timeline` |
| Runtime 状态 | `GET /api/tasks/:taskId/runtime/status` |
| Runtime 统计 | `GET /api/tasks/:taskId/runtime/stats` |
| Runtime 日志 | `GET /api/tasks/:taskId/runtime/logs` |
| Runtime 启动 | `POST /api/tasks/:taskId/runtime/start` |
| Runtime 停止 | `POST /api/tasks/:taskId/runtime/stop` |
| Runtime 清理 | `DELETE /api/tasks/:taskId/runtime` |
| 批次详情 | `GET /api/batches/:batchId` |
| 批次统计 | `GET /api/stats/batches` |
| 总览统计 | `GET /api/stats/overview` |
| 错误统计 | `GET /api/stats/errors` |
| 系统设置读取 | `GET /api/settings` |
| 系统设置更新 | `PUT /api/settings` |
| Skills 列表 | `GET /api/skills` |
| Skills 创建 | `POST /api/skills` |
| Skill 详情 | `GET /api/skills/:skillId` |
| Skill 更新 | `PUT /api/skills/:skillId` |
| Skill 删除 | `DELETE /api/skills/:skillId` |

### 2.3 当前初始化顺序

启动时会先执行：

1. `initializeSystemSettings()`
2. `initializeSkillRegistry()`
3. `initializeTaskStore()`

这意味着 FastAPI 版本也必须保留明确的启动初始化流程，不能只把模型建好就算完成。

---

## 3. 迁移原则

### 3.1 API 契约优先于内部实现

前端是否零改动，不是看“返回 JSON 长得像不像”，而是要同时满足：

1. URL 不变。
2. HTTP 方法不变。
3. 查询参数不变。
4. 请求体字段名不变。
5. 返回字段结构不变。
6. 状态码不变。
7. 错误码和错误文案尽量不变。

### 3.2 Skill-First，而不是逻辑写死

系统核心不是把“所有项目都当成 web 服务”，而是把每类项目的识别、构建、运行、部署规则沉淀为 skill。

主系统负责：

1. 任务调度
2. 状态机
3. 日志与审计
4. 执行环境管理
5. 容器与产物管理
6. 超时、重试、清理

skill 负责：

1. 项目识别规则
2. 构建命令
3. 启动命令
4. 健康检查建议
5. 部署方式建议
6. 已知问题与兜底策略

### 3.3 先能力对等，再增强可靠性

第一阶段目标不是做一个更先进的系统，而是做一个可以替换现有后端、并且前端能正常工作的系统。

### 3.4 双栈切换，不直接硬切

在 Python 后端完成真实验证前：

1. 保留 `src/` Node.js 后端。
2. 新后端放在 `backend/`。
3. 通过环境变量或启动脚本切换目标服务。

只有满足验收条件后，才进入旧后端移除流程。

---

## 4. 技术决策

### 4.1 Web 框架

- 采用 `FastAPI`
- 启动方式：`uvicorn backend.main:app --host 127.0.0.1 --port 3333`

### 4.2 ORM 与迁移

- ORM：`SQLAlchemy 2.x`
- 迁移工具：`Alembic`
- 会话管理：同步 SQLAlchemy Session 起步

说明：

当前项目大量操作是文件系统、Docker CLI、子进程和外部 HTTP，请求瓶颈不在数据库异步 IO。首版优先选择同步 Session，降低复杂度。后续若有明确瓶颈，再评估是否切异步引擎。

### 4.3 数据库

默认方案：

- 本地开发：`SQLite`
- 连接串：`sqlite:///./runtime/data/tasks.db`

生产可切换：

- `PostgreSQL`

要求：

1. 配置层通过 `DATABASE_URL` 切换。
2. Repository 层不写死 SQLite 特性。
3. SQLite 启用 WAL 模式。

### 4.4 长任务执行模型

主方案：

- API 层接单
- 数据先入库
- 使用 `Celery + Redis` 执行任务流水线

推荐角色拆分：

1. `FastAPI` 负责 HTTP API
2. `Celery Worker` 负责异步任务执行
3. `Redis` 负责 broker / result backend
4. `SQLAlchemy + DB` 负责任务元数据、审计日志、状态持久化

补充约束：

1. 每个 task 必须有明确状态机，至少包含 `queued`、`running`、`succeeded`、`failed`、`cancelled`。
2. 每个阶段必须落库 `current_stage`、开始时间、结束时间、错误摘要。
3. Celery 任务必须设计为幂等，避免重试造成容器、镜像、工作目录污染。
4. 所有外部执行步骤都要支持超时、重试上限和清理钩子。

建议的阶段状态：

1. `queued`
2. `repo_access`
3. `analyze`
4. `plan`
5. `build`
6. `package`
7. `deploy`
8. `health_check`
9. `finished`

### 4.5 Skill-First 架构

skill 不是文案模板，而是部署能力插件。

每个 skill 至少要回答五件事：

1. 它识别什么项目
2. 它输出什么交付物
3. 它怎么构建
4. 它怎么运行
5. 它怎么部署或归档

建议 skill 分两层：

1. 生态 skill
2. 通用能力 skill

生态 skill 示例：

- `python-fastapi`
- `python-package`
- `java-springboot`
- `go-service`
- `rust-cli`
- `node-express`
- `npm-library`
- `electron-desktop`
- `windows-exe`

通用能力 skill 示例：

- `dockerfile-generator`
- `http-health-check`
- `artifact-archiver`
- `wsl-runner`
- `monorepo-detector`

### 4.6 Docker 与执行环境策略

首版继续以 `subprocess` 调用 Docker CLI 为主，不强依赖 Python Docker SDK。

原因：

1. 与现有实现更接近。
2. 可控性更高。
3. 行为更容易与现网对齐。

### 4.7 WSL 作为一级执行后端

Windows 环境下，`WSL` 不作为临时兼容方案，而作为正式执行后端之一。

建议抽象统一执行层：

1. `local_windows`
2. `wsl`
3. `docker`
4. `remote_linux`（预留）

推荐首版策略：

1. API 服务可以运行在 Windows
2. Git、shell、Docker Compose、构建命令优先在 WSL 内执行
3. 所有执行后端都通过统一接口暴露：
   - `run_command`
   - `stream_logs`
   - `copy_in`
   - `copy_out`
   - `cleanup`

原因：

1. 大量项目天然假设 Linux shell 环境
2. Docker / Compose / 权限 / 路径行为在 WSL 中更接近真实部署环境
3. 可以减少在 Windows 原生命令行下的兼容性分支

补充约束：

1. 平台不仅要支持在 Windows 本机运行 API，还要支持 Windows 软件构建与交付。
2. 平台还要支持 Linux 服务器部署，首批目标发行版为 `Ubuntu` 和 `CentOS`。
3. 因此执行后端不能只围绕 `WSL + Docker` 设计，还要预留：
   - Windows 本机构建/打包
   - 远程 Linux 主机部署
   - 不同发行版的命令与服务管理差异

---

## 5. 推荐目录结构

```text
backend/
├── __init__.py
├── main.py
├── requirements.txt
├── .env.example
├── core/
│   ├── __init__.py
│   ├── config.py
│   ├── database.py
│   ├── response.py
│   └── lifecycle.py
├── models/
│   ├── __init__.py
│   ├── task.py
│   ├── skill.py
│   ├── audit_log.py
│   └── system_settings.py
├── workers/
│   ├── __init__.py
│   └── celery_app.py
├── executors/
│   ├── __init__.py
│   ├── base.py
│   ├── windows_executor.py
│   ├── wsl_executor.py
│   └── docker_executor.py
├── skillpacks/
│   ├── registry/
│   ├── builtin/
│   └── user/
├── schemas/
│   ├── __init__.py
│   ├── task.py
│   ├── skill.py
│   └── settings.py
├── repositories/
│   ├── __init__.py
│   ├── task_repository.py
│   ├── skill_repository.py
│   ├── settings_repository.py
│   └── audit_log_repository.py
├── routers/
│   ├── __init__.py
│   ├── health.py
│   ├── tasks.py
│   ├── batches.py
│   ├── stats.py
│   ├── skills.py
│   └── settings.py
├── services/
│   ├── __init__.py
│   ├── task_pipeline.py
│   ├── repository_analyzer.py
│   ├── config_generator.py
│   ├── deployment_executor.py
│   ├── docker_runtime.py
│   ├── health_checker.py
│   ├── failure_diagnosis.py
│   ├── repo_access.py
│   └── ai_client.py
├── scripts/
│   └── import_legacy_state.py
└── alembic/
    ├── env.py
    └── versions/
```

补充说明：

1. `schemas/` 单独拆出，避免 ORM 模型和 API 出参/入参混在一起。
2. `core/lifecycle.py` 负责启动初始化与关闭清理。
3. `scripts/import_legacy_state.py` 专门承接 JSON -> DB 导入。
4. `workers/celery_app.py` 负责 Celery 初始化与任务注册。
5. `executors/` 统一封装 Windows、WSL、Docker 等执行环境。
6. `skillpacks/` 用文件方式存放 skill 定义、模板和检测规则。

---

## 6. 数据模型设计

### 6.1 tasks 表

首版保持“兼容优先”，复杂结构先以 JSON 字符串或 JSON 列存储。

建议字段：

```sql
CREATE TABLE tasks (
    id TEXT PRIMARY KEY,
    batch_id TEXT,
    batch_index INTEGER,
    repo_url TEXT NOT NULL,
    branch TEXT NOT NULL DEFAULT 'main',
    status TEXT NOT NULL DEFAULT 'queued',
    current_stage TEXT NOT NULL DEFAULT 'queued',
    retry_count INTEGER NOT NULL DEFAULT 0,
    auto_retry BOOLEAN NOT NULL DEFAULT FALSE,
    analyze_only BOOLEAN NOT NULL DEFAULT FALSE,
    runtime_meta TEXT,
    project_profile TEXT,
    strategy TEXT,
    artifacts TEXT DEFAULT '[]',
    result TEXT,
    summary TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

约束要求：

1. `id`、`batch_id` 与现有前端字段命名对齐。
2. `status` 只能落当前系统承认的状态集合。
3. `updated_at` 每次更新任务时自动刷新。

### 6.2 skills 表

`skills` 不再作为 skill 主体存储，而是作为 skill 索引与运行态元数据表。

```sql
CREATE TABLE skills (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    source TEXT NOT NULL DEFAULT 'builtin',
    category TEXT NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    path TEXT NOT NULL,
    version TEXT,
    triggers TEXT NOT NULL,
    deployment TEXT NOT NULL,
    known_issues TEXT DEFAULT '[]',
    stats TEXT DEFAULT '{}',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 6.3 audit_logs 表

```sql
CREATE TABLE audit_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id TEXT NOT NULL,
    event TEXT NOT NULL,
    payload TEXT,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

### 6.4 system_settings 表

```sql
CREATE TABLE system_settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
```

### 6.5 不在首版处理的优化

以下内容先不做，避免过度设计：

1. `tasks` 子表拆分。
2. `skills` 关系化建模。
3. 审计日志异步写库。
4. 任务事件总线。

---

## 7. Skill-First 多语言部署架构

### 7.1 skill 的定位

skill 是项目类型适配器，不只是 prompt。

skill 输出的不是一句建议，而是一组可执行策略：

1. `classification`
2. `build_strategy`
3. `runtime_strategy`
4. `delivery_strategy`
5. `healthcheck_strategy`

### 7.2 skill 文件结构

建议采用文件化 skill：

```text
backend/skillpacks/builtin/
  python-fastapi/
    skill.yaml
    detectors/
    templates/
    prompts/
  java-springboot/
    skill.yaml
  go-service/
    skill.yaml
  rust-cli/
    skill.yaml
  npm-library/
    skill.yaml
  electron-desktop/
    skill.yaml
```

`skill.yaml` 建议字段：

```yaml
id: python-fastapi
name: Python FastAPI Service
category: backend_service
priority: 80
supports:
  languages: [python]
  delivery_types: [container_service]
detect:
  files:
    - pyproject.toml
    - requirements.txt
  any:
    - "fastapi"
build:
  install: "pip install -r requirements.txt"
  command: "python -m compileall ."
runtime:
  type: http_service
  start: "uvicorn app.main:app --host 0.0.0.0 --port 8000"
  port: 8000
deploy:
  type: docker
healthcheck:
  type: http
  path: /health
```

### 7.3 skill 匹配流程

建议流程：

1. 扫描仓库特征
2. 生成候选 skill 列表
3. 按优先级和置信度排序
4. 若命中多个冲突 skill，则进入歧义判定
5. 选出主 skill
6. 挂载通用能力 skill

### 7.4 skill 与主系统边界

主系统不负责理解每种语言的细节，只负责稳定执行。

主系统负责：

1. 调度
2. 状态
3. 日志
4. 资源控制
5. 重试
6. 清理
7. artifact 存储

skill 负责：

1. 检测
2. 构建命令
3. 启动命令
4. 健康检查规则
5. 交付方式判断
6. 特定语言的已知坑

### 7.5 skill 组合能力

复杂仓库不要求单一 skill 全包，可以组合。

例如：

1. `node-monorepo` + `node-express` + `dockerfile-generator`
2. `python-package` + `artifact-archiver`
3. `windows-exe` + `wsl-runner`

---

## 8. 多语言、多交付物项目分类与部署矩阵

分类优先看“交付目标”，不是先看“语言”。

### 8.1 交付类型

建议统一为以下几类：

1. `container_service`
2. `static_site`
3. `build_artifact`
4. `library_only`
5. `desktop_app`
6. `linux_server_service`
7. `windows_installer`

### 8.2 典型映射

| 项目类型 | 常见语言/生态 | 主要产物 | 默认策略 |
|---|---|---|---|
| Web 服务 | Python / Java / Go / Rust / Node | 容器服务 | 构建镜像并运行 |
| 前端站点 | Node / Vite / Next 导出 | 静态文件 | 静态托管或 Nginx 容器 |
| CLI 工具 | Go / Rust / Python / Node / C | 二进制或脚本产物 | 构建并归档 |
| 包管理库 | npm / pip / crate / Go module | 包文件 | 构建、测试、归档，不默认部署 |
| Windows 桌面端 | Electron / Tauri / PyInstaller / 原生 exe | exe/msi/zip | 构建并归档，不做 HTTP 健康检查 |
| Linux 服务器服务 | Python / Java / Go / Rust / Node / C | 二进制、配置、service 文件 | 部署到 Ubuntu / CentOS，支持 systemd |
| Windows 安装包 | Electron / Tauri / .NET / 原生程序 | exe/msi | 构建并归档，必要时支持静默安装脚本 |

### 8.3 语言建议方案

Python：

1. 服务类项目：容器化部署
2. 包项目：构建 wheel / sdist
3. 桌面端：PyInstaller 产物归档

Java：

1. Spring Boot：jar 构建后容器化
2. 多模块 Maven / Gradle：优先识别主模块，构建 artifact 或容器

Go：

1. HTTP 服务：二进制或容器化
2. CLI：构建单文件二进制并归档

Rust：

1. Web 服务：容器化
2. CLI：构建二进制归档
3. 若依赖 nightly，要在 skill 中显式声明

Node.js：

1. 服务类：容器化
2. 前端类：静态构建
3. npm 包：产物归档，不默认运行服务

C / C++：

1. 原生服务：构建后作为 artifact 或容器运行
2. 原生桌面程序：构建产物归档

Windows 软件：

1. `desktop_app`：生成 `exe` / `msi` / 压缩包
2. 支持安装参数、静默安装脚本、运行前依赖说明
3. 不默认要求 HTTP 健康检查

Linux 服务器：

1. `linux_server_service`：可走容器部署或原生部署
2. 原生部署需区分 `Ubuntu` 与 `CentOS`
3. 需要在 skill 中声明：
   - 包管理器需求
   - systemd service 模板
   - 端口与健康检查方式
   - 运行用户与工作目录

### 8.4 不支持的默认行为

以下项目即使识别成功，也不默认进入“容器部署”：

1. 纯 npm 包
2. 纯 pip 包
3. 纯 CLI 工具
4. 桌面应用
5. 纯 SDK / 库项目

---

## 9. API 契约迁移清单

---

## 7. API 契约迁移清单

这一节是开工前必须对照完成的内容。不是建议项，是验收依据。

### 7.1 必须一比一迁移的接口

| 接口 | 方法 | 验收要求 |
|---|---|---|
| `/health` | `GET` | 返回结构和当前服务一致 |
| `/api/tasks` | `POST` | 创建任务成功后返回 `201` |
| `/api/tasks/batch` | `POST` | 创建批次成功后返回 `201` |
| `/api/tasks` | `GET` | 支持 `status`、`keyword`、`batchId` 过滤 |
| `/api/tasks/:taskId` | `GET` | 返回完整任务详情 |
| `/api/tasks/:taskId` | `DELETE` | 保持运行中删除失败逻辑 |
| `/api/tasks/:taskId/retry` | `POST` | 保持重试判定与返回字段 |
| `/api/tasks/:taskId/ai/strategy` | `GET` | 保留默认兜底策略 |
| `/api/tasks/:taskId/ai/diagnosis` | `GET` | 保持失败诊断返回结构 |
| `/api/tasks/:taskId/logs` | `GET` | 保持 `type` 参数行为 |
| `/api/tasks/:taskId/timeline` | `GET` | 返回 `items` 数组 |
| `/api/tasks/:taskId/runtime/status` | `GET` | 行为与当前 Docker runtime 查询一致 |
| `/api/tasks/:taskId/runtime/stats` | `GET` | 行为与当前 Docker runtime 查询一致 |
| `/api/tasks/:taskId/runtime/logs` | `GET` | 行为与当前 Docker runtime 查询一致 |
| `/api/tasks/:taskId/runtime/start` | `POST` | 保持启动行为与错误处理 |
| `/api/tasks/:taskId/runtime/stop` | `POST` | 保持停止行为与错误处理 |
| `/api/tasks/:taskId/runtime` | `DELETE` | 保持清理行为与返回结构 |
| `/api/batches/:batchId` | `GET` | 保持批次详情结构 |
| `/api/stats/batches` | `GET` | 返回 `items` |
| `/api/stats/overview` | `GET` | 返回任务统计摘要 |
| `/api/stats/errors` | `GET` | 返回错误统计 |
| `/api/settings` | `GET` | 返回当前设置 |
| `/api/settings` | `PUT` | 保持设置校验与错误码 |
| `/api/skills` | `GET` | 支持 `language`、`category` 过滤 |
| `/api/skills` | `POST` | 重复创建时返回 `409` |
| `/api/skills/:skillId` | `GET` | 未找到返回 `404` |
| `/api/skills/:skillId` | `PUT` | 保持更新语义 |
| `/api/skills/:skillId` | `DELETE` | 保持删除语义 |

### 7.2 契约校验方式

必须保留一份对照表，逐项核验以下内容：

1. 请求方法
2. 路径
3. Query 参数
4. 请求体
5. 成功状态码
6. 成功响应字段
7. 失败状态码
8. 错误码
9. 默认错误文案

建议在 `docs/` 下额外新增：

- `docs/backend-api-contract-checklist.md`

---

## 10. 分阶段执行计划

本项目遵循“小步迁移、每阶段可验证、每阶段可回滚”。

### Phase 0：契约冻结与迁移基线

目标：先把当前 Node.js 行为固定下来，避免边迁移边漂移。

涉及文件：

1. `src/server.js`
2. `src/routes/tasks.js`
3. `docs/backend-migration-fastapi.md`
4. `docs/backend-api-contract-checklist.md`

交付物：

1. 路由清单
2. 响应结构清单
3. 错误码清单
4. 状态枚举清单
5. 历史数据字段映射表

验收标准：

1. 所有现有接口有书面契约说明。
2. 明确哪些行为是必须兼容，哪些允许调整。

回滚方式：

- 文档阶段，无需回滚。

### Phase 1：脚手架与数据层

目标：让 Python 后端能启动、能连库、能读写核心实体。

涉及目录：

1. `backend/main.py`
2. `backend/core/`
3. `backend/models/`
4. `backend/repositories/`
5. `backend/alembic/`

交付物：

1. FastAPI 应用骨架
2. SQLAlchemy 配置
3. Alembic 初始迁移
4. `tasks`、`skills`、`audit_logs`、`system_settings` 四张表
5. Celery 与 Redis 基础集成
6. 初始化生命周期逻辑

验收标准：

1. `uvicorn` 能本地启动。
2. `GET /health` 可用。
3. 数据库可自动初始化或可通过 Alembic 初始化。
4. Repository 层能完成任务、技能、设置的基础 CRUD。
5. Celery worker 可以消费最小示例任务。

回滚方式：

1. 停止 Python 服务。
2. 删除新建 SQLite 文件。
3. Node.js 后端继续作为唯一服务运行。

### Phase 2：静态查询路由迁移

目标：先迁移只读接口和纯数据接口，降低联调风险。

建议先做：

1. `GET /health`
2. `GET /api/tasks`
3. `GET /api/tasks/:taskId`
4. `GET /api/batches/:batchId`
5. `GET /api/stats/batches`
6. `GET /api/stats/overview`
7. `GET /api/stats/errors`
8. `GET /api/settings`
9. `GET /api/skills`
10. `GET /api/skills/:skillId`

验收标准：

1. 前端至少可以正常浏览列表、详情、统计、设置、技能页。
2. Python 接口返回结构与 Node 版本一致。
3. 至少完成一次前端联调冒烟。

回滚方式：

- 前端 API 指回 Node.js 服务。

### Phase 3：写接口与状态修改迁移

目标：迁移创建、更新、删除、重试等写操作。

包括：

1. `POST /api/tasks`
2. `POST /api/tasks/batch`
3. `POST /api/tasks/:taskId/retry`
4. `DELETE /api/tasks/:taskId`
5. `PUT /api/settings`
6. `POST /api/skills`
7. `PUT /api/skills/:skillId`
8. `DELETE /api/skills/:skillId`

验收标准：

1. 前端可完整发起任务。
2. 设置修改后能持久化。
3. Skills 的增删改查行为对齐原系统。
4. 常见错误码符合当前接口语义。

回滚方式：

1. 停止 Python 写流量。
2. 恢复 Node.js 为写入口。
3. 如发生脏数据，仅清理 Python DB，不影响原 JSON 状态文件。

### Phase 4：任务流水线、Skill 与 Docker/AI 集成

目标：迁移真正复杂的业务执行链路。

包括：

1. 仓库克隆
2. 仓库分析
3. skill 匹配
4. 配置生成
5. Docker 构建
6. Docker 启停和运行时状态
7. WSL 执行适配
8. 健康检查
9. 故障诊断
10. 时间线与日志读取

验收标准：

1. 提交一个真实仓库能跑通分析 -> 构建 -> 部署 -> 健康检查。
2. 中途失败时有可读的错误、日志和时间线。
3. skill 选择结果可解释、可追踪。
4. Runtime 接口能对运行中的容器做查询和操作。

回滚方式：

1. 停止 Python 流水线。
2. 恢复 Node.js `task-pipeline` 为主执行入口。

当前实现进度补充：

1. 真实 GitHub 仓库克隆已经接入。
2. README 与关键文件扫描已经接入。
3. 文件型 skill 匹配已经接入。
4. OpenAI 兼容接口的 AI 增强分析已经接入，且支持失败回退到规则链路。
5. `executionPlan` 草稿生成已经接入。
6. `Dockerfile` 与 `docker-compose.yml` 草稿生成已经接入。
7. `docker compose up`、runtime status、logs、stats、stop、cleanup 已经接入真实 Docker CLI。

因此当前项目已经不再停留在“骨架阶段”，而是进入了“主链路可运行、成功率仍需打磨”的阶段。

### Phase 5：切换与退役

目标：完成服务切换，但不立即删除旧实现。

步骤：

1. 默认启动脚本切到 Python。
2. Node.js 后端保留一个观察窗口。
3. 完成 3 到 5 个真实仓库样本验证。
4. 观察窗口内无阻塞问题后，再删除 `src/`。

验收标准：

1. 新后端连续完成真实任务样本。
2. 前端在默认配置下工作正常。
3. 运维启动方式已更新。

回滚方式：

1. 启动脚本切回 Node.js。
2. Python 后端保留但不接流量。

---

## 11. 数据迁移方案

### 9.1 数据来源

历史数据来自：

1. `runtime/state/tasks.json`
2. `runtime/state/skills.json`

### 9.2 迁移策略

建议保留导入能力，不强制首次上线就导入。

分两种模式：

1. 空库启动
2. 导入历史状态

### 9.3 导入要求

导入脚本必须：

1. 幂等执行。
2. 输出导入统计。
3. 记录失败项。
4. 对不兼容字段进行显式映射，而不是静默吞掉。

建议导入输出：

```text
Imported tasks: 120
Skipped tasks: 3
Imported skills: 18
Warnings: 2
```

---

## 12. 测试与验证要求

迁移完成不能只靠“接口能返回 200”判定成功。

### 10.1 代码级验证

Node.js 侧现有校验：

```bash
npx tsc --noEmit
npx eslint . --quiet
```

Python 侧建议补充：

```bash
python -m compileall backend
pytest
```

如果首阶段没有 `pytest`，文档里要明确写“暂未配置自动化测试”，不能省略。

### 10.2 接口级验证

至少覆盖：

1. 健康检查
2. 任务创建
3. 任务列表
4. 任务详情
5. 任务删除
6. 批次创建和批次详情
7. 设置读取与更新
8. Skills 增删改查
9. 运行时状态查询

### 10.3 业务级验证

必须至少跑通一个真实仓库样本：

1. 创建任务
2. 克隆仓库
3. 生成部署配置
4. 构建镜像
5. 启动容器
6. 健康检查
7. 查看日志和时间线

### 10.4 分层测试策略

为了避免每次回归都消耗大量时间并持续产生真实项目镜像，测试应分成三层：

第一层：规则与规划测试

1. 只测 `repository_scanner`
2. 只测 `execution_planner`
3. 只测 AI override 合并逻辑
4. 不克隆真实仓库
5. 不构建镜像

这一层应该成为后续最主要的测试层。

第二层：固定 smoke 镜像 / compose 测试

1. 使用固定、可复用的最小服务验证执行器链路
2. 只验证 `docker compose up / ps / logs / stats / stop / cleanup`
3. 不把 skill 推断正确性和执行器冒烟混在一起

建议固定 smoke 资产示例：

```yaml
services:
  smoke:
    image: python:3.12-alpine
    command: ["python", "-m", "http.server", "8080"]
    working_dir: /workspace
    ports:
      - "18080:8080"
```

这层的目标是验证执行器稳定性，而不是验证仓库理解能力。

第三层：真实仓库抽样回归

1. 只保留少量代表性 GitHub 仓库
2. 用于阶段性验证 skill 匹配、AI 分析与部署成功率
3. 不要求每轮功能改动都全量执行

建议只在里程碑阶段或 planner / AI / executor 发生重要变更时再跑。

### 10.5 当前测试策略调整建议

后续开发默认应优先：

1. 跑规则测试
2. 跑固定 smoke compose
3. 只在必要时跑真实仓库

避免把“真实仓库构建成功率测试”当成每轮开发的默认冒烟方式。

---

## 13. 风险与应对

| 风险 | 说明 | 应对 |
|---|---|---|
| Celery 任务幂等性不足 | 重试可能重复创建容器、镜像、工作目录 | 为 task 设计稳定资源命名和清理策略 |
| SQLite 并发有限 | 写压力增大时会锁竞争 | 启用 WAL；后续可切 PostgreSQL |
| API 兼容性被低估 | 前端依赖的不只是字段结构 | 用契约清单逐项对照 |
| JSON 字段过多 | 初期快，后期查询变难 | 首版接受，后续按真实查询热点拆表 |
| Docker 行为差异 | Python SDK 与 CLI 行为未必一致 | 首版继续使用 CLI |
| 新旧状态源并存 | 迁移期间容易出现双写混乱 | Node.js 保持只读或完全作为备用，不做双写 |
| WSL 路径与权限差异 | Windows 路径和 Linux 路径混用容易出错 | 通过统一 executor 层收敛路径转换 |
| skill 匹配冲突 | 一个仓库可能命中多个候选 skill | 增加优先级、置信度和人工兜底选择 |
| 项目并非可部署服务 | 有些项目只能构建，不能部署 | 先判断 delivery type，再决定是否部署 |

---

## 14. 待确认决策

正式开工前，需要明确：

### Q1：数据库起步方案

- [x] SQLite 起步，保留 PostgreSQL 切换能力
- [ ] 直接 PostgreSQL

建议：先选 SQLite，后续保留 PostgreSQL。

### Q2：异步执行方案

- [x] 直接使用 `Celery + Redis`
- [ ] 先 `BackgroundTasks`，后面再迁移

建议：直接使用 `Celery + Redis`。

### Q3：历史数据是否导入

- [ ] 导入 `runtime/state/tasks.json` 和 `runtime/state/skills.json`
- [x] 不导入，从空库开始

建议：当前没有必须保留的数据，可从空库开始；仍保留导入脚本能力，但不阻塞 Phase 1。

### Q4：Python 环境

- [x] 使用 `conda`
- [ ] 使用 `venv`

已确认：

1. 当前机器使用 `conda` 管理 Python 环境
2. 本项目可新建独立 conda 环境

建议：迁移文档与脚本按 `conda` 环境初始化编写，同时尽量保持对 `venv` 的兼容性。

### Q5：默认执行后端

- [x] `WSL`
- [ ] `local_windows`
- [ ] 混合模式

补充要求：

1. 默认执行后端为 `WSL`
2. 同时必须支持 Windows 软件构建/打包
3. 同时必须支持 Linux 服务器部署，目标平台包含 `Ubuntu` 和 `CentOS`

建议：默认选 `WSL`，Windows 承载 API 与管理层；平台内部保留 `local_windows` 和 `remote_linux` 两类执行能力。

### Q6：切换策略

- [x] 先双栈并行，再切主
- [ ] 直接替换 Node.js

建议：必须双栈过渡，不建议一步硬切。

---

## 15. 建议的启动依赖

`backend/requirements.txt` 草稿：

```txt
fastapi>=0.111.0
uvicorn[standard]>=0.29.0
sqlalchemy>=2.0.0
alembic>=1.13.0
pydantic>=2.0.0
pydantic-settings>=2.0.0
httpx>=0.27.0
python-dotenv>=1.0.0
openai>=1.0.0
jinja2>=3.1.0
celery>=5.3.0
redis>=5.0.0
```

如果确定使用 SQLite，同步驱动即可，不必首版引入 `aiosqlite`。

可选增强依赖：

```txt
flower>=2.0.0
pytest>=8.0.0
```

---

## 16. 最终执行建议

按当前仓库情况，建议这样落地：

1. 先做 Phase 0，补齐 API 契约清单。
2. 再做 Phase 1，搭好 Python 骨架、数据库和 Celery。
3. 先实现 skill 文件加载、匹配和执行后端抽象。
4. 优先迁移 GET 接口，先让前端“看得见数据”。
5. 再迁移写接口和任务流水线。
6. 最后切换默认启动方式，观察稳定后再删除 `src/`。

一句话结论：

这次迁移可以做，而且应该升级成一个 `Skill-First` 的多语言、多交付物部署平台，但仍然要按“契约冻结 -> 数据层与 Celery -> skill 体系 -> 只读接口 -> 写接口 -> 流水线 -> 切换”这个顺序推进。
