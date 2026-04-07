# AI + Skill Roadmap v1

> 文档版本：v1.0
> 创建时间：2026-04-03
> 适用范围：真实 GitHub 仓库自动识别、技能选择、部署规划
> 目的：明确后端后续改造方向，将项目识别主链路从“硬规则优先”升级为“规则提证据，AI 做理解，skill 沉淀经验”

---

## 1. 背景

当前后端主干已经具备：

1. 仓库拉取与扫描
2. skill 匹配
3. execution plan 生成
4. Dockerfile / Compose 产物生成
5. 任务状态流转与基础部署执行

但这套能力目前更接近“标准单服务项目识别器”，而不是真正面向真实世界 GitHub 仓库的自动部署系统。

`LuaN1aoAgent` 这类项目暴露出的不是个例问题，而是架构边界问题：

1. 项目启动方式可能主要写在 README 中，而不是写在固定入口文件里
2. README 中高价值信息往往不在文件开头
3. 项目可能是多进程、多角色拓扑，而不是单个 Web 服务
4. skill 不能只描述框架，还要描述运行形态和自动部署边界
5. 仅靠硬规则无法覆盖真实仓库的复杂性

因此，后续重心不应该继续堆零散规则，而应该转向：

1. 规则层负责提取稳定证据
2. AI 层负责理解项目
3. skill 层负责沉淀经验并约束 planner

---

## 2. 总体原则

### 2.1 规则不是大脑

规则层的职责应收敛为：

1. 文件结构扫描
2. 依赖提取
3. README 关键段提取
4. 候选命令提取
5. 端口、健康检查、运行角色线索提取

规则层不应继续承担“完整判断项目如何部署”的最终责任。

### 2.2 AI 不是全文阅读器

AI 的职责不是吞整仓库，而是消费经过提纯的结构化证据，输出：

1. 项目类型判断
2. 架构拓扑判断
3. 主服务识别
4. skill 类型推荐
5. 自动部署可行性判断
6. 风险和人工确认建议

### 2.3 skill 不只是框架模板

skill 不应只表达：

1. `flask`
2. `express`
3. `spring`

skill 还应表达：

1. 单服务 Web 项目
2. Web + Worker 双进程项目
3. Dashboard + Agent 项目
4. CLI / Batch / Job Runner 项目
5. 需要初始化知识库或外部资源的项目

### 2.4 保守优先

当证据不足时：

1. 允许 AI 输出低置信度
2. 允许 planner 退化为 `needs_manual_review`
3. 禁止误部署比禁止漏部署更重要

---

## 3. 现状问题

### 3.1 README 处理过于粗糙

当前仓库扫描对 README 的处理仍偏粗：

1. 容易只取前部片段
2. 容易把宣传内容、徽章、架构介绍和真实运行命令混在一起
3. 无法稳定命中 `Quick Start`、`Running`、`Deployment` 等高价值区段

### 3.2 Python 启动识别过窄

当前入口识别主要围绕：

1. `main.py`
2. `app.py`
3. `server.py`
4. `manage.py`

但真实项目常见情况包括：

1. `python -m web.server`
2. `python -m package.module`
3. 多个独立入口
4. 一个常驻服务 + 一个一次性 worker

### 3.3 planner 默认是单服务心智

当前 execution plan 更偏向于：

1. 一个项目只有一个主启动命令
2. 一个项目映射成一个 `app` 服务
3. 一个端口对应一个健康检查

这对多进程系统天然不适配。

### 3.4 skill 表达能力不足

当前 skill 主要表达生态和框架，不足以表达：

1. 项目角色划分
2. 多进程运行方式
3. 自动部署边界
4. 哪些进程可自动拉起，哪些必须人工确认

### 3.5 还没有真正的 AI 理解步骤

扫描结果、skill 选择、execution plan 仍然主要依赖规则层，没有形成：

扫描 -> AI 理解 -> skill 映射 -> planner

这条完整链路。

---

## 4. 目标架构

后续主链路建议调整为：

```text
Repository Clone
  -> Repository Scan
  -> Evidence Extraction
  -> Repo Understanding (AI)
  -> Skill Resolution
  -> Execution Planning
  -> Artifact Generation
  -> Deployment / Manual Review
```

### 4.1 各层职责

`Repository Scan`

1. 读取目录结构
2. 读取关键配置文件
3. 提取 README 关键区段
4. 生成候选入口和候选命令

`Repo Understanding (AI)`

1. 判断项目类型
2. 判断单进程 / 多进程
3. 识别主服务和辅助进程
4. 判断自动部署边界
5. 推荐 skill 类型

`Skill Resolution`

1. 将 AI 判断映射到最合适的 skill
2. 提供构建、运行、健康检查和已知风险经验

`Execution Planning`

1. 消费 AI + skill 结果
2. 生成部署计划
3. 在低置信度时降级为人工确认

---

## 5. 第一阶段目标

第一阶段不追求完整多服务部署，只做“AI 进入主链路”的最小闭环。

### 5.1 第一阶段必须完成

1. 扫描器输出更高价值的结构化证据
2. 新增 `repo understanding` AI 步骤
3. planner 可以消费 AI 给出的主运行时结论
4. 对低置信度项目进入 `needs_manual_review`

### 5.2 第一阶段暂不强求

1. 完整多服务 Compose 自动生成
2. worker 自动部署与调度
3. AI 参与失败诊断与日志摘要的全量上线
4. 所有 skill 格式一次性全面重构

---

## 6. 第一阶段模块改造

### 6.1 `backend/services/repository_scanner.py`

职责从“直接推断部署结果”降级为“提取证据”。

建议新增输出：

1. `readmeEvidenceBlocks`
2. `commandHints`
3. `runtimeCandidates`
4. `architectureSignals`
5. `documentationSignals`

#### README 处理策略

不再简单依赖 README 开头片段，而是：

1. 优先定位区段标题
2. 再抓取命中关键词附近上下文
3. 再提取命令代码块

建议关键词：

1. `quick start`
2. `getting started`
3. `run`
4. `running`
5. `start`
6. `usage`
7. `deployment`
8. `docker`
9. `compose`
10. `python -m`
11. `python `
12. `uvicorn`
13. `gunicorn`
14. `npm run`
15. `localhost:`
16. `worker`
17. `agent`
18. `dashboard`
19. `sqlite`
20. `redis`

#### Python 入口识别策略

入口识别应支持：

1. 固定入口文件
2. 模块式入口
3. 目录式入口
4. 多入口项目

例如：

1. `main.py`
2. `app.py`
3. `web/server.py`
4. `package/module.py`
5. 可映射为 `python -m package.module` 的目录结构

### 6.2 新增 `backend/services/repo_understanding.py`

该模块建议独立存在，不与现有 analyzer 完全混在一起。

职责：

1. 接收 scan result
2. 组装 AI payload
3. 调用 AI
4. 校验 AI 输出
5. 清洗为稳定 JSON

建议暴露接口：

1. `build_understanding_payload(scan: dict) -> dict`
2. `analyze_repository(scan: dict) -> dict`
3. `normalize_understanding(raw: dict) -> dict`

### 6.3 `backend/services/skill_loader.py`

第一阶段不一定重写 skill 文件格式，但需要让 skill 选择支持 AI 介入。

建议能力：

1. 接收 AI 推荐的 `recommendedSkillType`
2. 接收 AI 推荐的 `recommendedSkillId`
3. 在规则候选和 AI 候选之间进行加权
4. 无法稳定选中时保留候选列表和证据

### 6.4 `backend/services/execution_planner.py`

planner 不再只靠 fallback 猜 `startCommand`。

第一阶段最少支持：

1. 优先使用 AI 的 `primaryRuntime`
2. AI 明确判定 `needs_manual_review` 时停止硬猜
3. 保留 `secondaryRuntimes` 但暂不自动部署

### 6.5 `backend/workers/tasks.py`

主链路中新增一步：

1. clone
2. scan
3. repo understanding
4. skill resolution
5. execution planning
6. artifact generation
7. deploy or manual review

同时建议把 AI 理解结果落库进入策略字段，方便排查。

---

## 7. 第一阶段数据结构

### 7.1 扫描输出增强

建议在 scan result 中增加：

```json
{
  "readmeEvidenceBlocks": [
    {
      "source": "README.md",
      "section": "Quick Start",
      "kind": "command_context",
      "content": "python -m web.server",
      "lineStart": 314,
      "lineEnd": 322
    }
  ],
  "commandHints": [
    {
      "command": "python -m web.server",
      "source": "README.md",
      "roleHint": "web_service"
    }
  ],
  "runtimeCandidates": [
    {
      "name": "web",
      "role": "web_service",
      "command": "python -m web.server",
      "kind": "persistent",
      "port": 8088,
      "confidence": "medium"
    }
  ],
  "architectureSignals": [
    "multi_process_hint",
    "dashboard_hint",
    "worker_hint",
    "sqlite_shared_state"
  ]
}
```

### 7.2 Repo understanding 输出

AI 输出应固定为结构化 JSON，例如：

```json
{
  "projectType": "python_application",
  "architectureType": "web_plus_worker",
  "primaryRuntime": {
    "role": "web_service",
    "command": "python -m web.server",
    "port": 8088,
    "kind": "persistent"
  },
  "secondaryRuntimes": [
    {
      "role": "worker",
      "command": "python agent.py ...",
      "kind": "manual_trigger"
    }
  ],
  "deploymentReadiness": "partial_auto",
  "recommendedSkillType": "web_plus_worker",
  "recommendedSkillId": null,
  "confidence": "medium",
  "reasoningSummary": "README indicates a persistent dashboard plus a separate worker process."
}
```

### 7.3 策略落库字段

建议在任务策略中保留：

1. `understanding`
2. `understandingConfidence`
3. `understandingEvidence`

方便复盘和回归。

---

## 8. AI 输入与输出约束

### 8.1 AI 输入原则

AI 不直接读取整仓库，而是读取压缩后的高价值证据：

1. repo 基本信息
2. 顶层目录结构
3. key files
4. 依赖摘要
5. 命令候选
6. runtime candidates
7. README evidence blocks
8. 规则层初判结果

### 8.2 AI 输出原则

AI 输出必须是 JSON，不接受长篇自然语言直接驱动系统执行。

### 8.3 AI 回答范围

AI 只回答以下有限问题：

1. 这是什么项目类型
2. 是单进程还是多进程
3. 主服务是谁
4. 哪些是辅助进程
5. 当前是否适合自动部署
6. 推荐 skill 类型是什么
7. 哪些地方必须人工确认

---

## 9. Skill 演进方向

第一阶段不强制全面改 skill schema，但应提前明确后续方向。

skill 未来不应只描述框架，还应描述项目拓扑。

建议新增的 skill 类型方向：

1. `single-service-web`
2. `web-plus-worker`
3. `dashboard-plus-agent`
4. `cli-runner`
5. `job-runner`
6. `manual-deploy`

每类 skill 除了构建和启动信息，还应表达：

1. 常见入口模式
2. 常见部署前置条件
3. 可自动部署的范围
4. 不可自动部署时的降级策略
5. 已知风险

---

## 10. 对 `LuaN1aoAgent` 的目标结果

第一阶段完成后，对 `LuaN1aoAgent` 的期望不是“一步到位全自动双进程部署”，而是：

1. 能从 README 中识别出 `python -m web.server`
2. 能识别 `localhost:8088`
3. 能识别这是 `web + worker` 结构，而不是普通 Flask 服务
4. planner 不再生成空 `CMD`
5. 系统可以产出：
   - `partial_auto`
   - 或 `needs_manual_review`
6. 理由必须清楚可解释

如果进一步扩展多服务能力，才考虑自动处理 worker。

---

## 11. 验收标准

### 11.1 第一阶段验收

1. `LuaN1aoAgent` 能输出正确的 `primaryRuntime.command`
2. `LuaN1aoAgent` 能输出正确的 `primaryRuntime.port`
3. 项目架构可识别为 `web_plus_worker`
4. 不再误判为 Flask
5. 不再生成空 `CMD`
6. 不再在证据不足时误自动部署

### 11.2 测试建议

建议新增三类测试：

1. README 分段命中提取测试
2. AI understanding 结果清洗测试
3. planner 消费 AI 结果测试

---

## 12. 建议实施顺序

按投入产出比排序，建议先做：

1. 重构 `repository_scanner.py`
2. 新增 `repo_understanding.py`
3. 调整 `workers/tasks.py` 串联新步骤
4. 改造 `execution_planner.py` 消费 AI 结果
5. 最后再逐步演进 skill 结构

---

## 13. 一句话总结

后续系统能力的上限，不取决于“规则写了多少”，而取决于：

1. 规则是否能稳定提取高价值证据
2. AI 是否能基于证据正确理解项目
3. skill 是否能把这种理解沉淀成可复用经验
4. planner 是否能在高置信度时自动推进，在低置信度时安全降级

这个方向比继续堆零散识别规则更重要，也更接近真实世界 GitHub 自动部署平台该有的形态。

---

## 14. 落地回填与差异说明

> **Phase 1-5 落地执行后记** (2026-04)

在实际推进过程中，本 Roadmap 已平稳落地第一阶段，并作了如下适配调整：

1. **AI 解析兜底退化机制强化**：最初设想当 AI 识别失败、置信度低于阈值或宕机时直接转退 fallback。实际落地中改为了“强制兜底清洗 `needs_manual_review` 策略”。即如果在理解阶段发生代码崩溃报错（如超时或限流），系统一律视为 `needs_manual_review`，从根本上隔离了瞎猜式自动部署可能导致的风险。
2. **Planner 的阻断式拦截**：最初期望 AI 给什么字段，Planner 就吸收进去。实际上增加了更为刚性的逻辑判断：只要 AI 的 `deploymentReadiness` 为 `needs_manual_review`，无论它是否成功提取出了命令或推荐了什么 Skill，Planner **不得**进行硬性兜盘或自动拼接 start_command。
3. **日志规范与切面设计**：全面引入基于 `understanding.XXX` 维度的独立流水线审计点（AuditLog），相比起初直接作为“一次普通的 API 调用”隐藏在内部，更能彰显 Repo Understanding 的全集状态，使得任何自动化决策均能在平台层面有迹可循。
