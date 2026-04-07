# AI + Skill Implementation Checklist v1

> 文档版本：v1.0
> 创建时间：2026-04-03
> 适用范围：AI + skill 改造第一阶段落地
> 目的：将 [AI + Skill Roadmap v1](/E:/project/repo-auto-deployer/docs/ai-skill-roadmap-v1.md) 拆解为可直接开发的阶段任务表

---

## 1. 使用说明

本清单面向后端开发阶段执行，强调：

1. 先完成最小闭环，再扩展能力
2. 每个阶段都要有明确产物
3. 每个阶段都要可独立验证
4. 低置信度时优先保守降级

建议把每个阶段作为独立开发批次推进，不要一次性并行改完整条链路。

---

## 2. Phase 1：扫描器改造成证据提取器

### 2.1 目标

让扫描器不再只输出粗糙的 `readmeExcerpt` 和单一启动猜测，而是输出可供 AI 使用的结构化证据。

### 2.2 主要文件

1. [backend/services/repository_scanner.py](/E:/project/repo-auto-deployer/backend/services/repository_scanner.py)
2. [backend/tests/test_repository_scanner.py](/E:/project/repo-auto-deployer/backend/tests/test_repository_scanner.py)

### 2.3 开发任务

#### 文件：[backend/services/repository_scanner.py](/E:/project/repo-auto-deployer/backend/services/repository_scanner.py)

- [ ] 把 README 处理从“固定截断”改为“分段命中式提取”
- [ ] 新增 README section 定位逻辑
- [ ] 新增 README 命令代码块提取逻辑
- [ ] 新增关键词附近上下文提取逻辑
- [ ] 新增 `readmeEvidenceBlocks` 输出
- [ ] 新增 `commandHints` 输出
- [ ] 新增 `runtimeCandidates` 输出
- [ ] 新增 `architectureSignals` 输出
- [ ] 新增 `documentationSignals` 输出
- [ ] 扩展 Python 入口识别，支持模块式入口和目录式入口
- [ ] 避免将 README 徽章、链接、宣传文字错误当作启动命令

#### 文件：[backend/tests/test_repository_scanner.py](/E:/project/repo-auto-deployer/backend/tests/test_repository_scanner.py)

- [ ] 新增 README 分段提取测试
- [ ] 新增命令块提取测试
- [ ] 新增 `python -m package.module` 识别测试
- [ ] 新增多进程信号识别测试
- [ ] 新增“徽章内容不能误识别为启动命令”测试

### 2.4 输出定义

本阶段结束后，扫描结果至少应新增：

1. `readmeEvidenceBlocks`
2. `commandHints`
3. `runtimeCandidates`
4. `architectureSignals`
5. `documentationSignals`

### 2.5 验收标准

- [ ] `LuaN1aoAgent` 可从 README 中提取出 `python -m web.server`
- [ ] 可识别 `localhost:8088`
- [ ] `runtimeCandidates` 至少包含一个 `web_service`
- [ ] README 顶部徽章不再污染 `startupHints`

---

## 3. Phase 2：接入 Repo Understanding AI 步骤

### 3.1 目标

在扫描之后新增 AI 理解步骤，让后端首次具备“基于证据理解项目”的能力。

### 3.2 主要文件

1. [backend/services/repo_understanding.py](/E:/project/repo-auto-deployer/backend/services/repo_understanding.py)
2. [backend/services/ai_analyzer.py](/E:/project/repo-auto-deployer/backend/services/ai_analyzer.py)
3. [backend/tests/test_repo_understanding.py](/E:/project/repo-auto-deployer/backend/tests/test_repo_understanding.py)

### 3.3 开发任务

#### 文件：[backend/services/repo_understanding.py](/E:/project/repo-auto-deployer/backend/services/repo_understanding.py)

- [ ] 新建 `build_understanding_payload(scan)` 方法
- [ ] 新建 `analyze_repository(scan)` 方法
- [ ] 新建 `normalize_understanding(raw)` 方法
- [ ] 对 AI 输出做 JSON 结构校验
- [ ] 对缺失字段补默认值
- [ ] 对非法字段做兜底清洗
- [ ] 支持输出 `deploymentReadiness`
- [ ] 支持输出 `primaryRuntime`
- [ ] 支持输出 `secondaryRuntimes`
- [ ] 支持输出 `recommendedSkillType`
- [ ] 支持输出 `recommendedSkillId`

#### 文件：[backend/services/ai_analyzer.py](/E:/project/repo-auto-deployer/backend/services/ai_analyzer.py)

- [ ] 复用现有 AI 配置与调用链路
- [ ] 补充专用于 repo understanding 的 prompt/消息结构
- [ ] 明确输出必须为结构化 JSON
- [ ] 保证 AI 调用失败时可安全降级

#### 文件：[backend/tests/test_repo_understanding.py](/E:/project/repo-auto-deployer/backend/tests/test_repo_understanding.py)

- [ ] 新增 payload 构建测试
- [ ] 新增 understanding JSON 清洗测试
- [ ] 新增 AI 返回缺字段时的兜底测试
- [ ] 新增低置信度输出测试
- [ ] 新增 `LuaN1aoAgent` 样本测试

### 3.4 AI 输入字段建议

- [ ] repo 基本信息
- [ ] key files
- [ ] dependencies
- [ ] python entrypoints
- [ ] command hints
- [ ] runtime candidates
- [ ] readme evidence blocks
- [ ] architecture signals
- [ ] 规则层初判 language/framework/projectType

### 3.5 AI 输出字段建议

- [ ] `projectType`
- [ ] `architectureType`
- [ ] `primaryRuntime`
- [ ] `secondaryRuntimes`
- [ ] `deploymentReadiness`
- [ ] `recommendedSkillType`
- [ ] `recommendedSkillId`
- [ ] `confidence`
- [ ] `reasoningSummary`

### 3.6 验收标准

- [ ] AI 能将 `LuaN1aoAgent` 识别为 `web_plus_worker`
- [ ] AI 能识别主运行时为 `python -m web.server`
- [ ] AI 能输出 `8088`
- [ ] AI 调用失败时系统可安全回退

---

## 4. Phase 3：让 Skill 选择支持 AI 介入

### 4.1 目标

将 skill 选择从“纯规则命中”升级为“规则候选 + AI 裁决”。

### 4.2 主要文件

1. [backend/services/skill_loader.py](/E:/project/repo-auto-deployer/backend/services/skill_loader.py)
2. [backend/tests/test_skill_loader.py](/E:/project/repo-auto-deployer/backend/tests/test_skill_loader.py)

### 4.3 开发任务

#### 文件：[backend/services/skill_loader.py](/E:/project/repo-auto-deployer/backend/services/skill_loader.py)

- [ ] 为 `match_skills` 增加 AI understanding 输入参数
- [ ] 支持优先考虑 `recommendedSkillId`
- [ ] 支持按 `recommendedSkillType` 提升候选 skill 分数
- [ ] 保留规则匹配分数，避免完全黑盒化
- [ ] 在规则与 AI 冲突时输出冲突证据
- [ ] 在无法稳定选中 skill 时返回 ambiguous 结果

#### 文件：[backend/tests/test_skill_loader.py](/E:/project/repo-auto-deployer/backend/tests/test_skill_loader.py)

- [ ] 新增 AI 推荐 skill id 的命中测试
- [ ] 新增 AI 推荐 skill type 的加权测试
- [ ] 新增规则与 AI 冲突时的保守处理测试
- [ ] 新增无法稳定选型时的 ambiguous 测试

### 4.4 第一阶段注意事项

- [ ] 第一阶段不要求全面改 skill schema
- [ ] 第一阶段先支持 AI 影响排序，不要求 skill 体系一步到位重构

### 4.5 验收标准

- [ ] skill 选择结果可反映 AI 理解结论
- [ ] 无 skill 命中时不会误降级成错误框架
- [ ] 候选 evidence 可落库并供排查

---

## 5. Phase 4：Planner 消费 AI + Skill 结果

### 5.1 目标

让 execution planner 不再主要依赖 fallback 猜测，而是优先使用 AI 已确认的主运行时。

### 5.2 主要文件

1. [backend/services/execution_planner.py](/E:/project/repo-auto-deployer/backend/services/execution_planner.py)
2. [backend/tests/test_execution_planner.py](/E:/project/repo-auto-deployer/backend/tests/test_execution_planner.py)

### 5.3 开发任务

#### 文件：[backend/services/execution_planner.py](/E:/project/repo-auto-deployer/backend/services/execution_planner.py)

- [ ] 为 `build_execution_plan` 增加 understanding 输入
- [ ] 优先使用 `understanding.primaryRuntime.command`
- [ ] 优先使用 `understanding.primaryRuntime.port`
- [ ] AI 指定 `deploymentReadiness = needs_manual_review` 时停止硬猜
- [ ] AI 指定 `deploymentReadiness = partial_auto` 时允许只规划主服务
- [ ] 将 `secondaryRuntimes` 写入 plan 但暂不自动部署
- [ ] 为 plan 增加 `planSource` 或类似字段，标明来自 AI / skill / fallback

#### 文件：[backend/tests/test_execution_planner.py](/E:/project/repo-auto-deployer/backend/tests/test_execution_planner.py)

- [ ] 新增 AI 主运行时优先测试
- [ ] 新增 `partial_auto` 规划测试
- [ ] 新增 `needs_manual_review` 停止自动启动测试
- [ ] 新增 secondary runtimes 保留测试

### 5.4 验收标准

- [ ] `LuaN1aoAgent` 不再生成空 `CMD`
- [ ] `LuaN1aoAgent` 不再误判为 Flask
- [ ] plan 中可保留 `web_service` 与 `worker` 的区分
- [ ] 低置信度项目不再误自动部署

---

## 6. Phase 5：把新链路接入任务流水线

### 6.1 目标

让新的 scan -> understanding -> skill -> plan 流程真正进入 worker 主链路。

### 6.2 主要文件

1. [backend/workers/tasks.py](/E:/project/repo-auto-deployer/backend/workers/tasks.py)
2. [backend/tests/test_worker_tasks.py](/E:/project/repo-auto-deployer/backend/tests/test_worker_tasks.py)

### 6.3 开发任务

#### 文件：[backend/workers/tasks.py](/E:/project/repo-auto-deployer/backend/workers/tasks.py)

- [ ] 在 scan 后插入 repo understanding 步骤
- [ ] 将 understanding 结果写入 task strategy
- [ ] 审计日志新增 `understanding.completed`
- [ ] understanding 失败时记审计日志并安全降级
- [ ] 将 understanding 结果传入 skill loader
- [ ] 将 understanding 结果传入 execution planner
- [ ] 对 `needs_manual_review` 状态补充明确 summary

#### 文件：[backend/tests/test_worker_tasks.py](/E:/project/repo-auto-deployer/backend/tests/test_worker_tasks.py)

- [ ] 新增 understanding 成功路径测试
- [ ] 新增 understanding 失败降级测试
- [ ] 新增 understanding -> planner 透传测试
- [ ] 新增 manual review summary 测试

### 6.4 验收标准

- [ ] 主链路可记录 understanding 结果
- [ ] understanding 异常不会拖垮整个任务
- [ ] 审计日志能看出 AI 理解阶段输入和结论

---

## 7. Phase 6：文档与契约同步

### 7.1 目标

保证 AI + skill 新链路的设计、数据结构、API 预期与实施文档一致。

### 7.2 主要文件

1. [docs/ai-skill-roadmap-v1.md](/E:/project/repo-auto-deployer/docs/ai-skill-roadmap-v1.md)
2. [docs/ai-system-spec.md](/E:/project/repo-auto-deployer/docs/ai-system-spec.md)
3. [docs/skill-system-spec.md](/E:/project/repo-auto-deployer/docs/skill-system-spec.md)
4. [docs/README.md](/E:/project/repo-auto-deployer/docs/README.md)

### 7.3 开发任务

- [ ] 在 AI system spec 中加入 repo understanding 章节
- [ ] 在 skill system spec 中补充拓扑型 skill 演进方向
- [ ] 在 roadmap 中回填实际落地差异
- [ ] 在 docs 索引中加入 checklist 文档

---

## 8. Phase 7：真实仓库回归样本集

### 8.1 目标

避免后续每次改识别逻辑都只对单元测试负责，而不对真实仓库负责。

### 8.2 主要文件

1. [backend/tests/](/E:/project/repo-auto-deployer/backend/tests/)
2. 建议新增测试夹具目录
3. 可选新增 `docs` 中的样本清单说明

### 8.3 开发任务

- [ ] 建立真实项目样本类型清单
- [ ] 至少覆盖单服务 Web、文档驱动启动、多进程项目三类
- [ ] 为每类样本定义预期 understanding 结果
- [ ] 为每类样本定义预期 plan 行为

### 8.4 最低建议样本类型

- [ ] 标准单体 Python Web 服务
- [ ] 标准 Node Web 服务
- [ ] 文档驱动启动项目
- [ ] 多进程 `web + worker` 项目
- [ ] 不适合自动部署的 CLI 项目

---

## 9. 建议开发顺序

推荐按以下顺序推进：

1. Phase 1：扫描器证据提取
2. Phase 2：repo understanding AI
3. Phase 3：skill 选择接入 AI
4. Phase 4：planner 消费 AI 结果
5. Phase 5：worker 主链路串联
6. Phase 6：文档同步
7. Phase 7：真实仓库回归样本集

---

## 10. 每阶段完成定义

### Phase 1 完成定义

- [ ] 扫描结果新增 evidence blocks / runtime candidates
- [ ] 单测覆盖 README 提取和模块式入口识别

### Phase 2 完成定义

- [ ] understanding JSON 可稳定生成
- [ ] AI 调用失败可安全降级

### Phase 3 完成定义

- [ ] skill 选择能消费 AI 建议
- [ ] ambiguous 情况可解释

### Phase 4 完成定义

- [ ] planner 能优先使用 AI 主运行时
- [ ] 低置信度项目不会误部署

### Phase 5 完成定义

- [ ] 主链路已串联 understanding
- [ ] 审计日志可见 understanding 阶段

### Phase 6 完成定义

- [ ] 文档与实现字段命名一致

### Phase 7 完成定义

- [ ] 至少有一组真实仓库回归样本可重复验证

---

## 11. 一句话总结

这份 checklist 的核心不是“补更多规则”，而是把第一阶段真正做成一个能落地的 AI + skill 闭环：

1. 扫描器提证据
2. AI 做理解
3. skill 承接经验
4. planner 做保守决策
5. worker 串起主链路

做到这一步，系统才算开始从“规则驱动识别器”进入“面向真实仓库的智能部署平台”。
