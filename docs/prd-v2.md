# PRD v2 — GitHub 项目自动化部署平台（修订版）

> 基于 v1 实现现状与产品方向重新梳理
> 更新时间：2026-04-02

---

## 1. 产品定位（重新校准）

面向**安全研究 / AI 辅助漏洞挖掘**场景的 GitHub 仓库自动分析、智能分类、一键环境搭建平台。

核心价值：**让研究员从"搭环境"这件事上彻底解脱，把时间留给真正的漏洞分析。**

目标仓库的现实是：**种类极其复杂**。Web 服务、CLI 工具、桌面端、纯库、移动端……系统必须先理解"这是什么"，再决定"能不能跑、怎么跑"。

---

## 2. 核心设计原则

1. **分类优先于部署** — 先用 AI 读懂仓库是什么类型，再决定走什么路径，不对不可部署的项目浪费资源
2. **Skills 是核心资产** — 每次成功部署都是知识积累，Skills 驱动成功率持续提升
3. **Docker 是路径之一，不是唯一路径** — 根据项目类型走不同的部署策略
4. **容器状态可见可控** — 部署完的靶机需要实时可管理，不能部署完就不管

---

## 3. 项目类型体系

系统在分析阶段必须将仓库归类到以下类型之一：

| 类型 | 说明 | 部署路径 |
|---|---|---|
| `web_service` | 有 HTTP 端口的 Web 应用、API 服务 | Docker 容器化 |
| `cli_tool` | 命令行工具，无 HTTP 端口 | 进程安装 + 可执行环境 |
| `library` | 纯库/SDK，不可直接运行 | 静态分析入口 |
| `desktop_app` | GUI 桌面应用（Electron/Qt 等） | 标记不可部署 |
| `mobile` | Android/iOS 项目 | 标记不可部署 |
| `complex_service` | 依赖复杂企业中间件的服务 | 降级到 needs_manual_review |
| `unknown` | 无法识别 | AI 深度分析 + 人工介入 |

---

## 4. Skills 系统（核心新增）

### 4.1 什么是 Skill

Skill 是一个**可复用的部署知识包**，记录了某一类项目的完整部署方法论。

它是对现有 Templates（只有文件模板）的全面升级：

| 维度 | 现有 Templates | Skills |
|---|---|---|
| 粒度 | 单文件（Dockerfile/Compose） | 完整部署知识包 |
| 触发条件 | 手动选语言 | 自动匹配 |
| 失败知识 | 无 | 已知问题 + 修复方案 |
| 历史成功率 | 无 | 有，且持续更新 |
| 项目类型感知 | 无 | 覆盖所有类型 |
| 来源 | 手动创建 | 内置 + 自动学习 + 用户定义 |

### 4.2 Skill 数据结构

```json
{
  "skillId": "python-fastapi-sqlite",
  "name": "FastAPI + SQLite Web Service",
  "category": "web_service",
  "version": 1,
  "enabled": true,
  "source": "built_in",

  "triggers": {
    "language": "python",
    "dependencies": ["fastapi", "uvicorn"],
    "files": ["main.py", "app.py"],
    "confidence": 0.9
  },

  "deployment": {
    "type": "docker",
    "dockerfileTemplate": "...",
    "composeTemplate": "...",
    "healthEndpoint": "/docs",
    "expectedPort": 8000,
    "envHints": ["DATABASE_URL", "SECRET_KEY"]
  },

  "knownIssues": [
    {
      "pattern": "ModuleNotFoundError",
      "cause": "依赖未安装",
      "fix": "在 Dockerfile 增加 pip install -r requirements.txt"
    },
    {
      "pattern": "address already in use",
      "cause": "端口冲突",
      "fix": "检查端口占用，调整 publishedPort"
    }
  ],

  "stats": {
    "successCount": 47,
    "failureCount": 3,
    "successRate": 0.94,
    "lastUsedAt": "2026-04-01T12:00:00Z"
  },

  "createdAt": "2026-01-01T00:00:00Z",
  "updatedAt": "2026-04-01T12:00:00Z"
}
```

### 4.3 Skill 来源与生命周期

```
built_in     → 系统内置，覆盖最常见技术栈（随版本迭代扩充）
auto_learned → AI 推断成功后自动提炼，用户确认后入库
user_defined → 用户手动创建，针对特殊项目类型
```

### 4.4 Skill 匹配优先级

```
1. 历史记录匹配（最优先）
   同一 repoUrl 成功过 → 直接复用上次的配置快照

2. Skill 精确匹配
   依赖特征 + 文件特征 + 语言 → 命中某个 Skill → 按 Skill 走

3. Skill 模糊匹配
   部分条件满足 → 选置信度最高的 Skill，标注"推测使用"

4. AI 推断（兜底）
   无任何 Skill 匹配 → AI 读 README + 分析文件树 → 给出方案
   → 成功后提示用户"是否保存为新 Skill"
```

### 4.5 内置 Skill 列表（初始版）

**Web Service 类**
- `node-express` — Node.js + Express
- `node-express-mongo` — Node.js + Express + MongoDB
- `python-fastapi` — Python FastAPI
- `python-flask` — Python Flask
- `python-django` — Python Django
- `python-django-postgres` — Python Django + PostgreSQL
- `go-gin` — Go + Gin
- `go-fiber` — Go + Fiber
- `java-spring-boot` — Java Spring Boot
- `java-spring-boot-mysql` — Java Spring Boot + MySQL

**CLI Tool 类**
- `python-cli` — Python CLI（Click/Typer/argparse）
- `go-cli` — Go 二进制 CLI
- `node-cli` — Node.js CLI

**不可部署类（快速识别，立即跳过）**
- `electron-desktop` — Electron 桌面应用
- `android-mobile` — Android 项目
- `ios-mobile` — iOS 项目
- `pure-library-npm` — 纯 npm 包
- `pure-library-pip` — 纯 Python 包

---

## 5. 部署路径扩展

### 5.1 路径一：Docker 容器化（web_service）

现有实现的核心路径，保留并增强：
- 优先复用已有 Compose/Dockerfile
- 无配置时按匹配的 Skill 生成
- 无 Skill 时 AI 生成
- 标记配置来源：`existing` / `skill` / `ai` / `hybrid`

### 5.2 路径二：进程安装（cli_tool）

```
克隆仓库
    ↓
安装依赖（pip/npm/go build/cargo build）
    ↓
验证可执行（运行 --help 或 --version）
    ↓
状态标记为 "ready_to_execute"
    ↓
输出：可执行命令 + 工作目录路径
```

健康检查替换为"命令可正常退出"而非 HTTP 探活。

### 5.3 路径三：标记跳过（desktop/mobile/library）

```
AI 识别项目类型
    ↓
确认为不可部署类型
    ↓
状态直接标记为 "not_deployable"
    ↓
输出：项目类型 + 跳过原因 + 是否值得静态分析
```

不走构建流程，节省时间和资源。

---

## 6. 任务状态扩展

在 v1 基础上新增：

| 新增状态 | 说明 |
|---|---|
| `classifying` | AI 正在分析项目类型 |
| `skill_matching` | 正在匹配 Skill 知识库 |
| `not_deployable` | 确认为桌面/移动/纯库类，不走部署流程 |
| `ready_to_execute` | CLI 工具安装完毕，可执行 |
| `running` | 容器/进程处于运行中（部署后的持续状态） |
| `stopped` | 容器已手动停止，资源保留 |
| `crashed` | 容器意外退出，待处理 |

完整状态流转：

```
queued
  → classifying（新）
      → not_deployable（新，终态）
      → skill_matching（新）
          → planning → generating → building → starting → checking
              → succeeded → running（新，持续态）
                  → stopped（新）/ crashed（新）/ cleaned
          → analyzing → planning → ...（无 Skill 匹配时）
  → needs_manual_review（兜底终态）
  → failed（执行失败终态）
```

---

## 7. Docker 容器管理（新增模块）

部署成功后，容器不再是"只读数据"，而是需要持续管理的资源。

### 7.1 新增 API

```
GET  /api/tasks/:id/runtime/status
     → 实时查询容器状态（running/stopped/crashed）

GET  /api/tasks/:id/runtime/stats
     → CPU、内存、网络实时数据（docker stats --no-stream）

GET  /api/tasks/:id/runtime/logs?tail=200
     → 容器实时日志（docker compose logs）

POST /api/tasks/:id/runtime/stop
     → 停止容器（docker compose stop），保留镜像和配置

POST /api/tasks/:id/runtime/start
     → 重启容器（docker compose start）

DELETE /api/tasks/:id/runtime
     → 完全清理（已有）
```

### 7.2 靶机列表视图

前端新增"运行中"仪表板：

- 列出所有 `running` 状态的任务
- 显示：项目名、访问端口/URL、CPU/内存、运行时长、一键操作
- 支持直接点击访问部署地址

---

## 8. AI 推理模块（落地规划）

### 8.1 接入方式

新增 `ai-client.js` 模块，统一管理 LLM 调用。  
API key 和模型配置通过系统设置管理（新增字段）。

```js
// 系统设置新增字段
{
  aiProvider: "openai" | "anthropic" | "local",
  aiModel: "gpt-4o" | "claude-3-5-sonnet" | "...",
  aiApiKey: "sk-...",
  aiEnabled: true
}
```

### 8.2 AI 参与的三个环节

**环节 1：项目分类（最高优先级）**

输入：README.md + 文件树 + 依赖文件内容  
输出：
```json
{
  "projectCategory": "web_service",
  "isDeployable": true,
  "recommendedStrategy": "docker",
  "detectedFramework": "fastapi",
  "confidence": 0.92,
  "reason": "项目包含 FastAPI 依赖和 uvicorn 启动命令，为标准 Web 服务"
}
```

**环节 2：部署方案生成（无 Skill 匹配时）**

输入：项目分类结果 + 文件树 + 关键配置文件内容  
输出：Dockerfile + docker-compose.yml + .env 占位 + 风险提示

**环节 3：失败诊断**

输入：错误日志 + 当前 stage + 项目画像  
输出：
```json
{
  "errorCategory": "dependency_conflict",
  "rootCause": "Python 3.12 与 numpy 1.21 不兼容",
  "suggestions": ["降级到 python:3.10-slim 基础镜像"],
  "shouldRetry": true,
  "confidence": 0.87,
  "autoFix": {
    "available": true,
    "description": "修改 Dockerfile 基础镜像",
    "patch": "FROM python:3.10-slim"
  }
}
```

### 8.3 AI 降级策略

AI 不可用时（无 API Key / 调用失败）：
- 项目分类降级为规则推断（现有逻辑）
- 方案生成只走 Skill 匹配，无匹配则 `needs_manual_review`
- 失败诊断降级为关键词匹配（现有逻辑）

---

## 9. .env 占位文件生成

部署 Web 服务时，AI 分析出项目需要的环境变量：

```
检测来源：
  - README 中的环境变量说明
  - .env.example / .env.sample 文件
  - 源码中 process.env.XXX / os.getenv("XXX") 调用

生成 .env.template 文件：
  DATABASE_URL=           # 数据库连接串（必填）
  SECRET_KEY=             # JWT 签名密钥（必填）
  REDIS_URL=              # Redis 连接串（可选）
  PORT=8000               # 服务端口（默认 8000）

任务结果中标注 envHints，UI 提示用户填写
```

---

## 10. 批量任务增强

### 10.1 批量分析模式（新增）

不部署，只分析：批量输入仓库 URL，快速输出每个仓库的：
- 项目类型
- 是否可自动部署
- 匹配到的 Skill
- 预估成功率
- 风险点

用于在正式部署前快速筛选"值得看"的目标。

### 10.2 批量部署优先级队列

批量任务支持按预估成功率排序执行，高成功率的先跑。

---

## 11. 技术债清理（实现阶段必做）

在开始新功能前，先清理现有代码的重复和混乱：

| 问题 | 位置 | 处理方式 |
|---|---|---|
| `runCommand` 函数在 3 个文件各自定义 | `deployment-executor.js` / `health-checker.js` / `task-cleanup.js` | 提取为 `docker-client.js` |
| `sendJson` / `ok` / `fail` 在 `server.js` 和 `tasks.js` 重复 | 两个路由文件 | 提取为 `http-utils.js` |
| Templates 系统将被 Skills 替代 | `template-registry.js` | 在 Skills 稳定后逐步迁移 |

---

## 12. 实现阶段规划

### Phase 1 — 基础修复（当前最紧迫）

优先级：**P0，阻断性问题**

- [ ] 新增 Go / Java 内置 Dockerfile 模板（当前这两个栈必然失败）
- [ ] 提取公共 `docker-client.js`，消除 `runCommand` 重复
- [ ] 提取 `http-utils.js`，消除路由层重复

### Phase 2 — Skills 系统

- [ ] 设计 Skill 数据结构和存储（替代现有 Templates）
- [ ] 实现 Skill 匹配引擎（trigger 条件评估）
- [ ] 内置 10 个核心 Skill（覆盖最常见 Web 服务）
- [ ] Skill CRUD 管理 API（替代模板管理 API）
- [ ] 成功后自动提炼 Skill 的逻辑

### Phase 3 — 项目类型识别

- [ ] 实现规则层分类（基于文件名、依赖特征的快速分类）
- [ ] 新增 `not_deployable` 状态和桌面/移动类快速识别
- [ ] `classifying` / `skill_matching` 新状态接入流水线
- [ ] CLI 工具部署路径实现

### Phase 4 — AI 接入

- [ ] 实现 `ai-client.js` 统一调用模块
- [ ] 系统设置新增 AI 配置项（provider / model / key）
- [ ] AI 项目分类接入分析阶段
- [ ] AI 方案生成接入配置生成阶段（无 Skill 时兜底）
- [ ] AI 诊断升级（现有规则诊断替换为真实 LLM 分析）
- [ ] `.env` 占位文件生成

### Phase 5 — 容器实时管理

- [ ] `GET /api/tasks/:id/runtime/status` — 容器实时状态
- [ ] `GET /api/tasks/:id/runtime/stats` — 资源占用
- [ ] `GET /api/tasks/:id/runtime/logs` — 实时日志
- [ ] `POST /api/tasks/:id/runtime/stop` / `start` — 生命周期控制
- [ ] 任务状态新增 `running` / `stopped` / `crashed`
- [ ] 前端"运行中靶机"仪表板

### Phase 6 — 批量增强

- [ ] 批量分析模式（只分类，不部署）
- [ ] 批量部署优先级队列
- [ ] 成功率统计与趋势图

---

## 13. 成功标准（修订）

| 指标 | 目标 |
|---|---|
| Web 服务类项目首次部署成功率 | ≥ 70% |
| 命中已有 Skill 时成功率 | ≥ 90% |
| 桌面/移动/纯库类识别准确率 | ≥ 95%（不浪费构建时间） |
| 批量 10 个 URL 到全部分类完成 | < 2 分钟 |
| 容器状态查询延迟 | < 300ms |
