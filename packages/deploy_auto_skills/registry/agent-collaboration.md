# Skills v2 Agent 协作协议

这份文档定义 `skills-v2` 在多 Agent 体系里的协作边界。
目标不是让多个 Agent 重复读仓库，而是让它们围绕同一份证据分工工作。

---

## 1. 角色划分

### 主 Agent

主 Agent 负责：
1. 读取仓库证据
2. 按顺序加载 Skill
3. 形成项目理解报告
4. 选择部署策略
5. 向执行层下发结构化决策

主 Agent 不应：
1. 在项目类型未识别前直接生成部署产物
2. 忽略已经发现的官方入口
3. 因为某个生态熟悉就跳过证据收集

### Shadow Agent

Shadow Agent 负责：
1. 审查主 Agent 的判断是否遗漏关键证据
2. 审查主 Agent 是否误判项目类型
3. 审查主 Agent 是否过早进入兜底生成路径
4. 在失败后提供纠偏建议

Shadow Agent 不应：
1. 脱离主 Agent 的证据重新自由发挥
2. 在没有明确理由时推翻官方入口优先级
3. 把“能生成”当成“应该生成”

### Executor

Executor 负责：
1. 按选定入口执行构建、启动、校验
2. 收集构建日志、运行日志、健康检查结果
3. 将执行结果结构化回传给主 Agent

Executor 不应：
1. 自己修改部署策略
2. 自己切换到另一套入口
3. 在失败时私自生成新 Dockerfile 或新脚本

---

## 2. 协作顺序

推荐顺序如下：

1. 主 Agent 完成项目理解
2. 主 Agent 产出初步部署决策
3. Shadow Agent 审查决策
4. 主 Agent 合并审查意见并确定最终策略
5. Executor 执行
6. 若失败，则进入纠偏流程

---

## 3. 主 Agent 输出契约

主 Agent 在交给 Shadow Agent 或 Executor 前，至少应输出：

1. `artifactType`
2. `architectureType`
3. `entrypointCandidates`
4. `selectedEntrypoint`
5. `activeSkills`
6. `blockedActions`
7. `recommendedStrategy`
8. `allowGeneratedArtifacts`
9. `requiresManualReview`
10. `reasoningSummary`

---

## 4. Shadow Agent 审查清单

Shadow Agent 至少检查以下问题：

1. 是否遗漏了 `docker/`、`deploy/`、`ops/`、`infra/` 等目录
2. 是否遗漏了 Compose、Dockerfile、Makefile、脚本、README 部署段落
3. 是否把多服务项目误判为单服务
4. 是否把 monorepo 根目录误判为可直接安装目录
5. 是否把 CLI、桌面程序、框架仓库误判为 Web 服务
6. 是否在官方入口存在时仍然走兜底生成
7. 是否遗漏关键环境变量、数据库、外部服务依赖

建议输出：

1. `reviewStatus`
2. `missedEvidence`
3. `wrongAssumptions`
4. `correctionSuggestions`
5. `manualReviewRecommended`

---

## 5. Executor 输出契约

Executor 执行后至少回传：

1. `executedEntrypoint`
2. `buildStatus`
3. `runStatus`
4. `healthcheckStatus`
5. `logSummary`
6. `failureStage`
7. `rawEvidenceLocations`

---

## 6. 失败后的职责分配

### 主 Agent

主 Agent 负责判断：
1. 这是执行失败还是理解失败
2. 是否需要重新激活某些 Skill
3. 是否需要切换到人工复核

### Shadow Agent

Shadow Agent 负责追问：
1. 是不是入口选错了
2. 是不是仓库结构理解错了
3. 是不是构建链和包管理器选错了
4. 是不是遗漏了环境依赖

### Executor

Executor 负责补充：
1. 失败发生在构建、启动还是健康检查
2. 哪个文件、命令、容器、进程给出了直接证据

---

## 7. 禁止行为

在协作模式下，以下行为应视为违规：

1. 主 Agent 未完成理解就直接让 Executor 运行通用模板
2. Shadow Agent 不基于证据，只凭经验推翻主 Agent
3. Executor 在失败时私自修改入口或改写部署文件
4. 多个 Agent 各自维护不同版本的项目结论

---

## 8. 推荐实践

1. 所有 Agent 共用同一份项目理解报告
2. Shadow Agent 主要做纠偏，不重复全量探索
3. Executor 只执行被批准的策略
4. 生成型能力只作为最后兜底

