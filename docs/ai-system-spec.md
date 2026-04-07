# AI System Spec

> 文档版本：v1.0
> 创建时间：2026-04-02
> 适用范围：一键部署 GitHub 项目的 AI 分析、规划、诊断能力
> 目的：定义 AI 在仓库分析、skill 推荐、部署规划、失败诊断中的职责边界与输入输出

---

## 1. 为什么需要 AI

这套系统面对的不是“规范示例项目”，而是真实世界里的 GitHub 仓库。

这些仓库经常存在：

1. 没有部署文档
2. README 不完整或过期
3. 项目结构混乱
4. 同时包含多种语言和工具链
5. 缺少 Dockerfile、启动脚本或健康检查说明
6. 有历史遗留代码、实验代码、样例代码混在一起

因此平台不能只靠硬编码规则。

规则适合处理：

1. 文件识别
2. 依赖识别
3. 常见框架匹配
4. 标准构建命令

AI 适合处理：

1. 仓库意图理解
2. 非标准项目结构分析
3. README / 配置 / 代码交叉推断
4. 缺失信息补全建议
5. 部署失败原因诊断

一句话原则：

规则负责“确定性识别”，AI 负责“模糊推理与解释”。

---

## 2. AI 功能清单

首版 AI 功能分为 5 类：

1. `repository_analysis`
2. `skill_recommendation`
3. `deployment_planning`
4. `failure_diagnosis`
5. `log_summarization`

### 2.1 repo_understanding (仓库结构理解)

用途：

- 在规则提取的底层证据（如 README 块、依赖、进程信号）基础上做逻辑分析
- 判断仓库架构拓扑，分离主辅运行时
- 判断可用自动化程度（部署就绪度）

输出关注点：

1. 项目类型与架构拓扑
2. 主/辅运行时划分（指令与端口）
3. 自动化部署就绪度 (`deploymentReadiness`)
4. 建议关联的 Skill 类别与 ID
5. 置信度与推理摘要

### 2.2 skill_recommendation

用途：

- 在规则引擎已给出候选 skill 时，帮助解决歧义

典型场景：

1. 同时存在 `package.json` 和 `pyproject.toml`
2. Monorepo 中多个子项目混在一起
3. README 指向的启动方式与默认约定不一致

### 2.3 deployment_planning

用途：

- 在 skill 已选定后，补足部署计划中的缺失信息

输出关注点：

1. 构建顺序建议
2. 启动命令建议
3. 端口建议
4. 健康检查建议
5. 交付类型确认

### 2.4 failure_diagnosis

用途：

- 分析构建失败、运行失败、健康检查失败的根因

输出关注点：

1. 根因分类
2. 修复建议
3. 是否可自动重试
4. 是否需要人工介入

### 2.5 log_summarization

用途：

- 对超长日志做摘要，给 UI 和任务详情页展示更友好的结果

---

## 3. AI 在流水线中的位置

### 3.1 推荐阶段

Celery 流水线中，AI 主要参与这些阶段：

1. `scan`
2. `skill_match`
3. `plan`
4. `diagnosis`

### 3.2 阶段职责

`scan`

- 读取 README、关键配置、项目结构、入口文件线索
- 形成仓库分析摘要

`skill_match`

- 当规则引擎匹配出多个候选 skill 时，AI 做辅助判断

`plan`

- 在已有主 skill 的基础上，补充启动命令、端口、健康检查路径、部署方式建议

`diagnosis`

- 对失败阶段做归因和修复建议

### 3.3 不使用 AI 的阶段

以下阶段默认不依赖 AI：

1. `repo_access`
2. `build`
3. `package`
4. `deploy`
5. `cleanup`

AI 可以辅助解释，但不能成为这些阶段执行成功的前置条件。

---

## 4. AI 输入源

AI 不应直接吃整个仓库，而应吃“筛选过的上下文”。

### 4.1 允许输入

1. 仓库文件树摘要
2. README 内容
3. `package.json`
4. `pyproject.toml`
5. `requirements.txt`
6. `pom.xml`
7. `build.gradle`
8. `Cargo.toml`
9. `go.mod`
10. `Dockerfile`
11. `docker-compose.yml`
12. 启动脚本
13. CI 配置
14. 失败日志摘要

### 4.2 输入限制

1. 不把整个仓库原样塞给模型
2. 单次输入优先控制在“关键文件 + 摘要”
3. 对超长文件先做切片或摘要
4. 二进制文件不送入 AI

### 4.3 上下文构造顺序

推荐顺序：

1. 文件树摘要
2. README
3. 关键配置文件
4. 候选入口文件
5. 规则引擎的初步判断

这样 AI 不是从零猜，而是在已有规则基础上补判断。

---

## 5. AI 输出契约

所有 AI 输出都必须是结构化 JSON，不接受自由散文直接驱动执行。

### 5.1 repo_understanding 输出

```json
{
  "projectType": "web_plus_worker",
  "architectureType": "multi_process",
  "primaryRuntime": {
    "role": "web",
    "command": "python -m web.server",
    "port": 8000,
    "kind": "persistent"
  },
  "secondaryRuntimes": [
    {
      "role": "worker",
      "command": "celery -A worker.app worker",
      "port": null,
      "kind": "persistent"
    }
  ],
  "deploymentReadiness": "partial_auto",
  "recommendedSkillType": "web_service",
  "recommendedSkillId": "python-fastapi",
  "confidence": "high",
  "reasoningSummary": "识别到包含 Web 服务及 Celery 队列处理的复合结构。建议启动 Web，要求人工复核 Worker。"
}
```

### 5.2 deployment_planning 输出

```json
{
  "recommendedExecutor": "wsl",
  "buildCommands": [
    "pip install -r requirements.txt"
  ],
  "startCommand": "uvicorn app.main:app --host 0.0.0.0 --port 8000",
  "healthcheck": {
    "type": "http",
    "path": "/health",
    "port": 8000
  },
  "deployMode": "docker",
  "artifacts": [
    "image"
  ],
  "risks": [
    "No explicit production config found"
  ]
}
```

### 5.3 failure_diagnosis 输出

```json
{
  "category": "dependency_install_failed",
  "summary": "Build failed because a system package required by a Python dependency is missing.",
  "rootCause": "Missing OS-level build dependency",
  "retryable": false,
  "nextAction": "manual_review",
  "suggestions": [
    "Add the required system package to the base image",
    "Use a build image with compiler toolchain"
  ]
}
```

---

## 6. 规则与 AI 的边界

### 6.1 规则优先

以下内容优先由规则引擎决定：

1. 文件是否存在
2. 基本语言识别
3. 标准框架识别
4. 已知 skill 的确定命中
5. 明确的 delivery type

### 6.2 AI 辅助

AI 只在以下场景参与：

1. 规则不足以唯一判断
2. 项目结构不规范
3. 需要跨 README、配置、代码做综合推断
4. 失败诊断和修复建议

### 6.3 AI 不能做的事

AI 不得：

1. 直接生成并执行危险命令
2. 绕过 skill 与 executor 的约束
3. 覆盖平台安全规则
4. 在无结构化校验的情况下直接控制部署

平台原则是：

- AI 提建议
- 平台做校验
- executor 负责执行

---

## 7. AI 降级策略

AI 不是强依赖组件，平台必须支持 AI 不可用时继续执行基础流程。

### 7.1 典型失败

1. provider 超时
2. provider 不可用
3. 返回无效 JSON
4. 结果置信度过低

### 7.2 降级规则

1. 若仓库规则已足够明确，则跳过 AI
2. 若 AI 分析失败，则回退到规则引擎结果
3. 若 AI 诊断失败，则返回基础失败摘要
4. 若 AI 计划失败，则只使用 skill 默认配置

### 7.3 低置信度处理

若 AI 输出 `confidence < 0.6`：

1. 标记为 `ambiguous`
2. 不自动做高风险部署动作
3. 任务结果中记录“需要人工确认”

---

## 8. AI Provider 抽象

### 8.1 provider 类型

首版支持：

1. OpenAI 兼容接口
2. 本地 Ollama
3. 预留其他 provider

### 8.2 统一接口

```python
class AIClient:
    def analyze_repository(self, context): ...
    def recommend_skill(self, context): ...
    def generate_plan(self, context): ...
    def diagnose_failure(self, context): ...
    def summarize_logs(self, context): ...
```

### 8.3 配置项

建议配置：

1. `AI_PROVIDER`
2. `AI_BASE_URL`
3. `AI_API_KEY`
4. `AI_MODEL_ANALYZE`
5. `AI_MODEL_DIAGNOSE`
6. `AI_TIMEOUT_SECONDS`
7. `AI_MAX_RETRIES`

---

## 9. 成本、超时与缓存

### 9.1 成本控制

建议：

1. 同一任务的仓库分析结果可缓存
2. 大仓库优先做规则筛选，再送 AI
3. 同类失败日志先摘要再诊断

### 9.2 超时控制

建议默认：

1. 仓库分析：30 到 60 秒
2. 部署规划：20 到 40 秒
3. 故障诊断：30 到 60 秒

### 9.3 缓存策略

可缓存对象：

1. 仓库分析摘要
2. skill 推荐结果
3. 失败诊断结果

缓存键建议包含：

1. 仓库 URL
2. commit hash 或分支
3. 关键文件摘要 hash
4. skill 版本
5. 模型名

---

## 10. 多 Agent 协作与反幻觉校正机制

### 10.1 为什么不能只靠一个主 agent

单个 agent 长时间围绕同一问题持续推理，容易出现：

1. 被自己前面的错误假设绑架
2. 在上下文越来越长时产生幻觉
3. 用“自洽”替代“真实”
4. 在证据不足时过度推断

因此，AI 系统不能只设计一个主 agent。

### 10.2 建议角色

首版建议 3 个核心角色：

1. `CoordinatorAgent`
2. `EvidenceAgent`
3. `ChallengeAgent`

可选第 4 个角色：

4. `DiagnosisAgent`

### 10.3 `CoordinatorAgent`

职责：

1. 汇总规则引擎结果
2. 决定是否需要 AI 子任务
3. 生成初版分析和执行计划
4. 综合 Evidence / Challenge 的结果

约束：

1. 不直接无限续写自我推理
2. 结论必须引用证据来源
3. 当置信度不足时必须输出 `ambiguous`

### 10.4 `EvidenceAgent`

职责：

1. 只补证据，不下最终结论
2. 定向找 README、入口文件、启动脚本、CI、Docker 线索
3. 帮主 agent 缩小歧义范围

适用场景：

1. 仓库过大
2. 候选 skill 太多
3. README 和代码冲突
4. 缺少明确入口

### 10.5 `ChallengeAgent`

职责：

1. 专门质疑主结论
2. 找替代假设
3. 找证据缺口
4. 阻止“看起来很合理但其实在猜”的结论

适用场景：

1. 置信度低
2. 多个候选 skill 分差接近
3. 准备执行高风险动作
4. README 与配置矛盾

### 10.6 `DiagnosisAgent`

职责：

1. 只在失败后参与
2. 不参与前置规划
3. 基于阶段日志和错误结果做归因

这样可以避免“规划者给自己找借口”。

### 10.7 触发规则

不是每次都要完整跑多 agent。

建议触发条件：

1. 规则引擎无法唯一命中 skill
2. AI 置信度低于阈值
3. 仓库属于 monorepo
4. 缺少 README 或部署文档
5. 没有 Dockerfile / 启动脚本
6. 即将执行高风险部署动作
7. 构建或部署失败后

### 10.8 协作流程

推荐流程：

1. 规则引擎先产出初步判断
2. `CoordinatorAgent` 生成第一版分析
3. `ChallengeAgent` 对第一版分析发起挑战
4. 若证据不足，则触发 `EvidenceAgent` 补上下文
5. `CoordinatorAgent` 重新综合，生成最终计划

### 10.9 上下文隔离原则

最重要的设计点：

1. `EvidenceAgent` 可以继承主上下文
2. `ChallengeAgent` 尽量不要继承主结论，只拿证据材料
3. `DiagnosisAgent` 只拿失败日志、阶段事件和计划摘要

这样可以降低“二次 agent 只是重复主 agent 观点”的风险。

### 10.10 输出结构

`ChallengeAgent` 推荐输出：

```json
{
  "verdict": "challenge",
  "confidence": 0.71,
  "issues": [
    "Current conclusion assumes this is a deployable web service, but no confirmed HTTP entrypoint was found."
  ],
  "missingEvidence": [
    "No explicit health endpoint",
    "No verified startup command"
  ],
  "alternativeHypotheses": [
    {
      "type": "library_only",
      "confidence": 0.62
    }
  ],
  "recommendedNextStep": "collect_more_context"
}
```

---

## 11. Prompt 设计规范

### 11.1 不能用万能 prompt

AI prompt 不能设计成：

- “帮我分析这个项目怎么部署”

必须按任务拆分：

1. 仓库分析 prompt
2. skill 推荐 prompt
3. 部署规划 prompt
4. 故障诊断 prompt

### 11.2 Prompt 基本原则

每个 prompt 都必须：

1. 只解决一个问题
2. 只接收必要上下文
3. 输出固定 JSON
4. 明确“不知道就返回 ambiguous”
5. 不允许编造文件或框架

### 11.3 Prompt 上下文结构

推荐结构：

1. 任务目标
2. 规则引擎已有判断
3. 文件树摘要
4. 关键文件片段
5. 明确问题列表
6. JSON 输出 schema

### 11.4 禁止项

Prompt 中建议明确禁止：

1. 猜测不存在的框架
2. 假设仓库一定是 web 服务
3. 输出自由散文替代 JSON
4. 忽略证据不足的情况

---

## 12. 大型仓库上下文裁剪与分层分析策略

### 12.1 原则

大型项目绝不能把整个仓库直接发给 AI。

必须采用：

1. 规则预筛选
2. 关键文件抽样
3. 疑点定向深挖

### 12.2 三层分析模型

第一层：仓库地图

读取：

1. 顶层目录树
2. 关键配置文件名
3. README
4. Docker / CI / lockfile 信号

目标：

1. 识别仓库整体结构
2. 找到候选部署单元

第二层：关键文件抽样

只读取高价值文件：

1. `README.md`
2. `package.json`
3. `pyproject.toml`
4. `requirements.txt`
5. `pom.xml`
6. `build.gradle`
7. `Cargo.toml`
8. `go.mod`
9. `Dockerfile`
10. `docker-compose.yml`

目标：

1. 基本判断项目类型
2. 缩小候选 skill

第三层：疑点定向深挖

只在必要时追加：

1. 入口文件
2. 启动脚本
3. CI workflow
4. deploy 脚本
5. service 配置

目标：

1. 解决歧义
2. 补足启动与部署缺失信息

### 12.3 仓库摘要器

建议在 AI 之前加一个本地 `context builder`：

职责：

1. 生成目录树摘要
2. 识别关键文件
3. 提取依赖和脚本信息
4. 提取入口与端口线索
5. 控制 token 预算

它输出的不是原始仓库，而是“精选上下文包”。

### 12.4 Token 预算机制

建议每次 AI 调用都带预算限制：

1. 单个 README 最多 8KB
2. 单个配置文件最多 6KB
3. 单个源码文件最多 4KB
4. 最多 8 个关键文件
5. 总上下文不超过预设阈值

超出后采用：

1. 截断
2. 摘要
3. 二轮分析

### 12.5 收益递减停止规则

为了避免 AI 无限续写和越想越偏，建议加停止条件：

1. 达到最大轮次
2. 达到 token 预算上限
3. 连续两轮新增证据低于阈值
4. 连续两轮结论无显著变化

命中这些条件后：

1. 停止进一步对话
2. 输出当前最佳结果
3. 若置信度不足则标记 `ambiguous`

### 12.6 两阶段 AI 分析

推荐拆成两轮：

第一轮：粗分类

回答：

1. 这是什么项目
2. 候选 skill 是什么
3. 交付类型是什么

第二轮：细规划

回答：

1. 启动命令
2. 健康检查
3. 构建顺序
4. 风险点

---

## 13. 安全与审计

### 10.1 输入安全

1. 不把 secrets 原样送入 AI
2. 不上传整个仓库的私密文件
3. 对环境变量、token、密钥做脱敏

### 10.2 输出安全

1. AI 输出必须经过 schema 校验
2. 命令必须经过平台白名单或安全校验
3. 高风险建议必须标记，不自动执行

### 10.3 审计要求

每次 AI 调用至少记录：

1. taskId
2. provider
3. model
4. feature
5. 输入摘要
6. 输出摘要
7. 耗时
8. 是否命中缓存

---

## 14. 首版落地建议

首版最值得先做的 AI 功能是：

1. `repository_analysis`
2. `failure_diagnosis`

第二优先级：

1. `skill_recommendation`
2. `deployment_planning`

最后再做：

1. `log_summarization`

原因：

1. 仓库分析决定“能不能理解这个项目”
2. 失败诊断决定“出了问题能不能解释”
3. 这两个点对用户感知价值最高

---

## 15. 一句话原则

AI 不是为了替代 skill 和规则，而是为了让系统在面对“不规范、缺文档、混合结构”的 GitHub 仓库时，仍然能做出足够靠谱的分析、推荐和诊断。
