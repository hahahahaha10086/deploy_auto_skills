# Skill System Spec

> 文档版本：v1.0
> 创建时间：2026-04-02
> 适用范围：FastAPI 后端迁移后的 Skill-First 部署平台
> 目的：定义 skill 文件格式、匹配流程、执行后端接口、Celery 状态机与产物规范

---

## 1. 目标

这份文档解决四个实施层问题：

1. skill 到底长什么样
2. skill 怎么匹配和冲突消解
3. Windows / WSL / Linux 目标环境怎么统一执行
4. Celery 任务状态和阶段事件如何落库

它是 [backend-migration-fastapi.md](/E:/project/repo-auto-deployer/docs/backend-migration-fastapi.md) 的实施细则，不替代迁移方案本身。

---

## 2. 术语

### 2.1 skill

skill 是“项目类型适配器”，负责输出某类仓库的识别、构建、运行、部署规则。

### 2.2 capability skill

不直接定义项目类型，而是提供通用能力的 skill。

示例：

1. `dockerfile-generator`
2. `artifact-archiver`
3. `http-health-check`
4. `wsl-runner`

### 2.3 delivery type

项目最终交付目标类型。

首版固定支持：

1. `container_service`
2. `static_site`
3. `build_artifact`
4. `library_only`
5. `desktop_app`
6. `linux_server_service`
7. `windows_installer`

### 2.4 executor

统一命令执行后端。

首版支持：

1. `wsl`
2. `local_windows`
3. `remote_linux`

---

## 3. Skill 存储结构

### 3.1 目录结构

```text
backend/skillpacks/
├── builtin/
│   ├── python-fastapi/
│   │   ├── skill.yaml
│   │   ├── templates/
│   │   ├── prompts/
│   │   └── examples/
│   ├── java-springboot/
│   │   └── skill.yaml
│   ├── go-service/
│   │   └── skill.yaml
│   └── windows-exe/
│       └── skill.yaml
├── user/
│   └── custom-skill/
│       └── skill.yaml
└── registry/
    └── index.json
```

### 3.2 存储原则

1. skill 主体存文件，不存数据库正文
2. 数据库存索引、启用状态、使用统计、覆盖关系
3. skill 文件应支持 git 管理和 review
4. 每个 skill 目录必须包含一个 `skill.yaml`

---

## 4. `skill.yaml` 规范

### 4.1 最小字段

```yaml
id: python-fastapi
name: Python FastAPI Service
version: 1.0.0
kind: ecosystem
category: backend_service
priority: 80
enabled: true
supports:
  languages: [python]
  delivery_types: [container_service, linux_server_service]
detect:
  files_any:
    - pyproject.toml
    - requirements.txt
  dependencies_any:
    - fastapi
build:
  install:
    - pip install -r requirements.txt
  command:
    - python -m compileall .
runtime:
  type: http_service
  start:
    - uvicorn app.main:app --host 0.0.0.0 --port 8000
  ports:
    - 8000
deploy:
  default: docker
healthcheck:
  type: http
  path: /health
artifacts:
  outputs:
    - type: image
known_issues: []
```

### 4.2 字段说明

必填字段：

1. `id`
2. `name`
3. `version`
4. `kind`
5. `category`
6. `priority`
7. `supports`
8. `detect`
9. `build`
10. `deploy`

可选字段：

1. `runtime`
2. `healthcheck`
3. `artifacts`
4. `known_issues`
5. `notes`

### 4.3 `kind` 枚举

1. `ecosystem`
2. `capability`
3. `override`

### 4.4 `category` 建议值

1. `backend_service`
2. `frontend_site`
3. `cli_tool`
4. `package_library`
5. `desktop_application`
6. `native_service`

### 4.5 `deploy.default` 枚举

1. `docker`
2. `artifact_only`
3. `static_hosting`
4. `linux_service`
5. `windows_installer`
6. `manual_review`

---

## 5. 检测规则

### 5.1 检测输入

仓库扫描阶段至少产出这些信息：

1. 顶层文件列表
2. 关键依赖文件
3. lockfile 信息
4. 语言线索
5. Dockerfile / Compose 信息
6. 启动脚本线索
7. Monorepo 线索

### 5.2 检测字段

`detect` 支持以下字段：

1. `files_any`
2. `files_all`
3. `dependencies_any`
4. `dependencies_all`
5. `commands_any`
6. `markers_any`

### 5.3 评分机制

每个命中的 skill 生成一个匹配分：

`score = base_priority + evidence_score - conflict_penalty`

推荐规则：

1. `priority` 作为基准分
2. 命中文件证据加分
3. 命中依赖证据再加分
4. 与排斥条件冲突时减分

### 5.4 冲突处理

若多个 skill 得分接近：

1. 分差大于等于 15，直接取最高分
2. 分差小于 15，标记为 `ambiguous`
3. 若存在 `override` skill，可覆盖默认选择
4. 保留候选列表到任务结果中，便于排查

### 5.5 多 skill 组合

首版规则：

1. 只允许 1 个主 skill
2. 允许 0 到 N 个 capability skill
3. capability skill 只能增强，不得改写主 skill 的 delivery type

---

## 6. Skill 输出契约

skill 选中后，必须生成统一的 `execution_plan`。

### 6.1 `execution_plan` 结构

```json
{
  "primarySkillId": "python-fastapi",
  "capabilitySkillIds": ["dockerfile-generator", "http-health-check"],
  "deliveryType": "container_service",
  "executor": "wsl",
  "build": {
    "install": ["pip install -r requirements.txt"],
    "commands": ["python -m compileall ."]
  },
  "runtime": {
    "type": "http_service",
    "start": ["uvicorn app.main:app --host 0.0.0.0 --port 8000"],
    "ports": [8000]
  },
  "deploy": {
    "mode": "docker"
  },
  "healthcheck": {
    "type": "http",
    "path": "/health"
  },
  "artifacts": {
    "expected": ["image"]
  }
}
```

### 6.2 平台侧只消费统一计划

主系统不直接读具体 skill 细节，只消费 `execution_plan`。

这样可以保证：

1. skill 可替换
2. 执行器可替换
3. 任务流水线不和语言细节耦合

### 6.3 与 AI 多 agent 结果的衔接

`execution_plan` 的生成顺序建议固定为：

1. 规则引擎给出初步 skill 候选
2. `CoordinatorAgent` 生成第一版判断
3. `ChallengeAgent` 检查是否存在反例或证据不足
4. 若有缺口，`EvidenceAgent` 补充上下文
5. 最终由 `CoordinatorAgent` 输出正式 `execution_plan`

约束：

1. skill 系统不能直接消费自由文本结论
2. 只接受结构化 JSON 结果
3. 当 AI 结果标记为 `ambiguous` 时，不得自动进入高风险部署

---

## 7. 执行后端规范

### 7.1 执行后端接口

所有 executor 都必须实现同一组能力：

```python
class BaseExecutor:
    def run_command(self, command, cwd, env=None, timeout=None): ...
    def stream_command(self, command, cwd, env=None, timeout=None): ...
    def file_exists(self, path): ...
    def ensure_dir(self, path): ...
    def copy_in(self, source, target): ...
    def copy_out(self, source, target): ...
    def remove_path(self, path): ...
    def resolve_path(self, path): ...
```

### 7.2 `wsl` executor

适用场景：

1. Linux shell 构建
2. Docker / Compose
3. Python / Node / Go / Rust 服务类项目

要求：

1. 支持指定 distro
2. 支持 Windows 路径转 WSL 路径
3. 支持在日志里回显原始命令
4. 支持超时中断

### 7.3 `local_windows` executor

适用场景：

1. Windows 安装包
2. `.exe` / `.msi` 构建
3. 依赖 Windows 原生工具链的项目

要求：

1. 支持 PowerShell 执行
2. 支持 Windows 路径原样处理
3. 支持静默安装与卸载命令

### 7.4 `remote_linux` executor

适用场景：

1. 部署到 Ubuntu / CentOS
2. 原生 Linux 服务部署
3. 容器或非容器服务发布

要求：

1. 支持 SSH 连接
2. 支持上传产物
3. 支持 systemd 服务部署
4. 支持区分 Ubuntu / CentOS 的命令差异

### 7.5 发行版差异要求

对 Linux 目标主机，skill 或 deploy 层需声明：

1. 包管理器：`apt` / `yum` / `dnf`
2. 服务管理器：默认 `systemd`
3. 目录规范
4. 运行用户
5. 防火墙或端口暴露要求

---

## 8. 交付物规范

### 8.1 artifact 类型

首版统一支持：

1. `image`
2. `binary`
3. `archive`
4. `wheel`
5. `npm_package`
6. `jar`
7. `exe`
8. `msi`
9. `static_bundle`
10. `service_bundle`

### 8.2 artifact 元数据

每个 artifact 至少记录：

```json
{
  "type": "exe",
  "name": "app-installer.exe",
  "path": "runtime/artifacts/task_xxx/app-installer.exe",
  "size": 123456,
  "checksum": "sha256:...",
  "createdAt": "2026-04-02T12:00:00Z"
}
```

### 8.3 非部署型项目规则

以下 delivery type 默认不进入“部署”阶段：

1. `library_only`
2. `build_artifact`
3. `desktop_app`
4. `windows_installer`

这些项目在 `package` 阶段完成后即可结束，状态记为成功。

---

## 9. Celery 任务状态机

### 9.1 顶层状态

任务顶层状态：

1. `queued`
2. `running`
3. `succeeded`
4. `failed`
5. `cancelled`

### 9.2 阶段状态

建议固定以下阶段：

1. `queued`
2. `prepare`
3. `repo_access`
4. `scan`
5. `skill_match`
6. `plan`
7. `build`
8. `package`
9. `deploy`
10. `health_check`
11. `cleanup`
12. `finished`

### 9.3 状态迁移规则

1. `queued -> running` 只能发生一次
2. 任一阶段失败，顶层状态转 `failed`
3. 非部署型项目可在 `package` 后直接跳到 `finished`
4. 清理失败不能覆盖主失败原因，只能作为附加事件

### 9.4 重试规则

1. 只有标记为可重试的失败类型允许自动重试
2. 自动重试前必须执行清理钩子
3. `retry_count` 达上限后不再重试
4. 重试要保留历史阶段事件，不覆盖原记录

### 9.5 Celery 任务划分

首版建议：

1. 一个 repo 任务对应一个主 Celery task
2. 阶段内部先串行执行
3. batch 任务由上层 API 拆成多个独立 task

---

## 10. 阶段事件格式

### 10.1 审计事件结构

```json
{
  "taskId": "task_xxx",
  "event": "stage_started",
  "payload": {
    "stage": "build",
    "attempt": 1,
    "executor": "wsl",
    "skillId": "python-fastapi"
  },
  "timestamp": "2026-04-02T12:00:00Z"
}
```

### 10.2 事件类型

首版至少支持：

1. `task_queued`
2. `task_started`
3. `stage_started`
4. `stage_succeeded`
5. `stage_failed`
6. `retry_scheduled`
7. `artifact_created`
8. `task_succeeded`
9. `task_failed`
10. `cleanup_started`
11. `cleanup_finished`

### 10.3 错误记录要求

阶段失败时至少记录：

1. `stage`
2. `errorCode`
3. `message`
4. `retryable`
5. `executor`
6. `skillId`

---

## 11. 默认 skill 清单建议

首版建议优先内建这些 skill：

1. `python-fastapi`
2. `python-package`
3. `java-springboot`
4. `go-service`
5. `go-cli`
6. `rust-service`
7. `rust-cli`
8. `node-express`
9. `vite-static-site`
10. `npm-library`
11. `electron-desktop`
12. `windows-exe`
13. `linux-systemd-service`

通用 capability skill：

1. `dockerfile-generator`
2. `http-health-check`
3. `artifact-archiver`
4. `wsl-runner`
5. `systemd-service-generator`

---

## 12. 首版不做的事

为了避免过度设计，以下内容暂不进入首版：

1. skill 热加载
2. skill 远程市场
3. 多主 skill 编排
4. 图形化 skill 编辑器
5. 分布式多 worker 调度策略优化

---

## 13. 实施顺序建议

建议按这个顺序实现：

1. 建 `skill.yaml` 解析器和 schema 校验
2. 建 skill 扫描与匹配器
3. 建 AI `context builder` 和多 agent 协作接口
4. 建 `execution_plan` 统一结构
5. 建 `wsl` / `local_windows` / `remote_linux` executor 接口
6. 建 Celery 主任务和阶段事件写库
7. 先接入 2 到 3 个代表性 skill 跑通
8. 再扩展语言和交付物覆盖面

一句话原则：
 
先把“平台骨架 + 代表性 skill + 统一执行接口”做稳，再扩 skill 数量，不要一开始就追求全覆盖。

---

## 14. 拓扑型 Skill 演进方向

在 AI 完成初步的 `repo_understanding` 改造后，识别出带有主/辅运行时（如 `web_plus_worker`）的架构将变得常态化。为了让这些分析能够被系统完全自动驾驶化，Skill Schema 的下一步进化方向需要支持“拓扑编排”。

### 14.1 引入 `topology` 类型

将来，`kind` 可以拓展支持 `topology` 或 `composed` 类型：

```yaml
kind: topology
components:
  web:
    skill: python-fastapi
  worker:
    skill: celery-worker
```

### 14.2 AI 推荐直接承接

当 AI 输出 `projectType: web_plus_worker` 时，如果 Skill 库中存在适配该架构的 `topology` Skill，该方案将无缝被 Execution Planner 解析为多容器部署计划。

这种演进将避免后端必须通过 `partial_auto` 让用户人工执行辅助运行时，实现对真实世界项目的“全架构部署”覆盖。
