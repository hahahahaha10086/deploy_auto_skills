# Skills v2 部署上下文落盘契约

这份文档定义：`skills-v2` 在完成环境探测、部署决策、部署执行后，应如何把结果稳定落盘到项目目录中，供其他 Skill 或 Agent 继续消费。

目标是让部署结果不再只存在于对话文本里，而是形成统一、可复用、可追踪的项目内事实文件。

---

## 1. 总原则

部署 Skill 的职责，不应只停留在“给出建议”。

在具备项目写入能力时，部署流程应把结构化结果写入项目目录，形成后续流程的输入。

这个落盘文件应满足：

1. 能被主 Agent 读取
2. 能被 Shadow Agent 读取
3. 能被漏洞验证、运维排障、后续自动化复用
4. 能在失败时保留纠偏信息

---

## 2. 推荐落盘文件

推荐统一使用：

```text
<repo-root>/vuln-validation/context/deployment_context.yaml
```

如需 JSON 兼容，可允许：

```text
<repo-root>/vuln-validation/context/deployment_context.json
```

但 v2 默认推荐 YAML，因为更适合 Agent 与人工同时阅读。

---

## 3. 推荐目录结构

如果仓库内不存在对应目录，部署流程应优先创建：

```text
<repo-root>/
  vuln-validation/
    context/
      deployment_context.yaml
    cases/
    runs/
    evidence/
    summaries/
```

说明：

1. `context/` 用于放部署事实
2. `cases/`、`runs/`、`evidence/`、`summaries/` 供后续验证流程使用
3. 部署 Skill 不负责写漏洞结论，但应负责把工作区骨架准备好

---

## 4. 写入时机

部署 Skill 不应只在“全部成功后”才写文件。

建议在三个阶段更新同一个文件：

### 阶段 1：Probe 完成后

至少写入：

1. `deployment_context.environment_confirmed`
2. `deployment_context.target_environment`
3. `probe_facts`

作用：

让后续流程尽早获得真实环境事实，而不是继续靠猜。

### 阶段 2：部署决策完成后

补充写入：

1. `deployment_context.strategy`
2. `deployment_context.selected_entrypoint`
3. `deployment_context.blocked_actions`
4. `deployment_context.requires_manual_review`

作用：

让执行层和下游 Skill 知道“当前决定用什么入口、哪些动作被禁止”。

### 阶段 3：部署执行后

补充写入：

1. `deployment_execution`
2. `failure_correction`

作用：

记录构建、运行、健康检查以及失败纠偏信息。

---

## 5. 最小结构

推荐最小结构如下：

```yaml
contract_version: "1.0"
producer: "deploy-skill"

deployment_context:
  environment_confirmed: true
  target_environment: "ubuntu"
  environment_compatibility: "high"
  strategy: "reuse_existing_compose"
  selected_entrypoint: "docker/docker-compose.yaml"
  blocked_actions: []
  requires_manual_review: false

probe_facts:
  host: {}
  tools: {}
  capabilities: {}
  permissions: {}

deployment_execution:
  executed_entrypoint: "docker/docker-compose.yaml"
  build_status: "success"
  run_status: "success"
  healthcheck_status: "success"
  failure_stage: ""
  log_summary: ""
  raw_evidence_locations: []

failure_correction:
  failure_category: ""
  wrong_assumption: ""
  correction_action: ""
  should_retry: false
  requires_manual_review: false
```

---

## 6. 与现有契约的关系

这个落盘文件并不是新发明一套结构，而是把 v2 里已有结构统一固化到项目内。

字段来源：

1. `probe_facts` 对应 `probe-contract.md`
2. `deployment_context` / `deployment_execution` 对应 `runtime-contract.md`
3. `failure_correction` 对应失败纠偏结果契约

因此：

- 不应与现有契约冲突
- 应优先复用已有字段名和语义

---

## 7. 落盘责任边界

部署 Skill 应负责写：

1. 环境事实
2. 部署策略
3. 执行状态
4. 失败纠偏信息

部署 Skill 不应负责写：

1. 漏洞 verdict
2. exploit chain 价值判断
3. access scope 结论

这些属于漏洞验证或安全分析阶段职责。

---

## 8. 失败场景要求

即使部署失败，也不应放弃落盘。

失败场景至少应写清：

1. `failure_stage`
2. `log_summary`
3. `failure_category`
4. `wrong_assumption`
5. `correction_action`
6. `should_retry`

这样下游流程能区分：

- 是项目起不来
- 还是入口选错了
- 还是环境权限不够

---

## 9. 最小行为要求

如果当前执行器或 Agent 还未完全程序化，最低也应保证：

1. 若项目内不存在 `vuln-validation/context/`，则创建
2. Probe 完成后写入一次 `deployment_context.yaml`
3. 部署决策完成后更新一次
4. 部署执行结束后再更新一次

做到这一步，就已经比“结果只留在聊天里”强很多。

---

## 10. 对其他 Skill 的价值

一旦有了统一落盘文件，以下流程都会受益：

1. 漏洞验证 Skill 可直接复用环境事实
2. Shadow Agent 可复核部署假设
3. 失败纠偏不需要重新收集上下文
4. 人工排查时不需要倒翻对话历史

---

## 11. 推荐后续动作

如果程序侧继续演进，建议：

1. 让 Executor 在每个关键阶段自动刷新该文件
2. 让主 Agent 在输出中显式引用该文件路径
3. 让依赖环境事实的下游 Skill 优先读取该文件，而不是重复推断
