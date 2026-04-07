# Skills v2 运行时契约

这份文档定义 `skills-v2` 被主 Agent、Shadow Agent、Executor 使用时的结构化结果格式。
目标是让文档型 Skill 后续可以稳定接入程序化加载和决策流程。

---

## 1. 总体原则

Skill 是 Markdown 文档，但运行时结果应尽量结构化。

也就是说：

1. 人读的是 `SKILL.md`
2. Agent 输出的是统一字段
3. 程序消费的是稳定契约

---

## 2. 项目理解结果

主 Agent 在项目理解阶段建议输出如下结构：

```json
{
  "artifactType": "web-service",
  "architectureType": ["multi-service", "monorepo"],
  "entrypointCandidates": [
    {
      "type": "compose",
      "path": "docker/docker-compose.yaml",
      "confidence": "high",
      "source": "entrypoint.existing-compose"
    }
  ],
 "targetEnvironment": "ubuntu",
  "environmentCompatibility": "high",
  "environmentRisks": [],
  "probeFacts": {
    "tools": {
      "docker": true,
      "dockerCompose": true,
      "conda": false
    }
  },
  "activeSkills": [
    "artifact.web-service",
    "architecture.multi-service",
    "entrypoint.existing-compose",
    "environment.ubuntu",
    "guard.reuse-official-config-first"
  ],
  "blockedActions": [
    "generate_root_level_dockerfile"
  ],
  "recommendedStrategy": "reuse_existing_compose",
  "allowGeneratedArtifacts": false,
  "requiresManualReview": false,
  "risks": [
    "monorepo_root_not_runnable"
  ],
  "reasoningSummary": "仓库存在官方 Compose，且结构显示为多服务项目，应优先复用现有编排。"
}
```

---

## 3. 字段说明

### artifactType

表示交付物主类型。

建议值示例：

1. `web-service`
2. `cli-tool`
3. `desktop-app`
4. `framework-library`
5. `build-only-project`

### architectureType

表示结构特征，可多个并存。

建议值示例：

1. `single-service`
2. `multi-service`
3. `monorepo`
4. `frontend-backend-split`
5. `agent-server`

### entrypointCandidates

表示候选入口列表。

每个候选建议包含：

1. `type`
2. `path`
3. `confidence`
4. `source`

### targetEnvironment

表示当前部署目标环境。

建议值示例：

1. `windows`
2. `linux`
3. `ubuntu`
4. `centos`
5. `wsl`

### environmentCompatibility

表示当前项目与目标环境的兼容程度。

建议值示例：

1. `high`
2. `partial`
3. `low`
4. `unknown`

### environmentRisks

表示目标环境带来的额外风险。

### probeFacts

表示由 Probe 采集到的主机与工具事实。

这部分不要求一开始完整，但建议至少包含：

1. `host`
2. `tools`
3. `capabilities`
4. `toolVersions`

### activeSkills

表示本次决策中实际生效的 Skill。

### blockedActions

表示被 guard 或决策层禁止的动作。

### recommendedStrategy

表示推荐的部署策略。

建议值示例：

1. `reuse_existing_compose`
2. `reuse_existing_dockerfile`
3. `reuse_makefile_or_script`
4. `reuse_documented_manual_flow`
5. `generate_fallback_artifacts`
6. `manual_review_only`

### allowGeneratedArtifacts

布尔值，表示是否允许进入兜底生成路径。

### requiresManualReview

布尔值，表示是否必须转人工复核。

### risks

表示当前阶段识别到的主要风险。

### reasoningSummary

给人看的简短总结，不要求冗长。

---

## 4. Shadow Agent 审查结果

Shadow Agent 建议输出：

```json
{
  "reviewStatus": "needs_correction",
  "missedEvidence": [
    "docker/docker-compose.yaml"
  ],
  "wrongAssumptions": [
    "assumed_single_service_root_app"
  ],
  "correctionSuggestions": [
    "activate entrypoint.existing-compose",
    "block root-level Dockerfile generation"
  ],
  "manualReviewRecommended": false
}
```

---

## 5. Executor 执行结果

Executor 建议输出：

```json
{
  "executedEntrypoint": "docker/docker-compose.yaml",
  "buildStatus": "failed",
  "runStatus": "not_started",
  "healthcheckStatus": "not_started",
  "failureStage": "build",
  "logSummary": "frontend service failed during dependency installation",
  "rawEvidenceLocations": [
    "runtime/logs/task_xxx/build.log"
  ]
}
```

---

## 6. 失败纠偏结果

在失败后，主 Agent 或 Shadow Agent 建议输出：

```json
{
  "failureCategory": "wrong_entrypoint_selection",
  "wrongAssumption": "treated_repo_as_single_node_service",
  "correctionAction": "switch_to_existing_compose",
  "shouldRetry": true,
  "requiresManualReview": false
}
```

---

## 7. 最小可用要求

如果程序侧暂时还没有完整解析能力，最低也应保证：

1. 有统一的 `activeSkills`
2. 有统一的 `recommendedStrategy`
3. 有统一的 `blockedActions`
4. 有统一的 `requiresManualReview`
5. 有统一的 `targetEnvironment`
6. 有统一的 `probeFacts`

这样即使先走半结构化实现，也不会把 v2 Skill 重新退回纯自由发挥。
