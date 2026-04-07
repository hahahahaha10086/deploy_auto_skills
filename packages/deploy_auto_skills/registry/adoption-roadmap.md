# Skills v2 最小接入路线图

这份文档描述 `skills-v2` 从文档体系走向程序接入的最小实施路径。
目标是逐步替换旧逻辑，而不是一次性重写整套部署系统。

---

## Phase 1：静态接入

目标：

1. 程序可以发现 `skills-v2`
2. 可以建立 Skill 索引
3. 可以按类别列出可用 Skill

这一阶段建议完成：

1. 扫描 `skills-v2/` 下所有 `SKILL.md`
2. 解析 frontmatter
3. 暴露一个只读的 Skill 列表接口
4. 记录 `name`、`description`、`category`、`path`

成功标准：

1. 后端能稳定返回 v2 Skill 列表
2. 不与旧版 `backend/skillpacks/` 混淆

---

## Phase 2：规则命中

目标：

1. 程序可根据仓库证据匹配基础 Skill
2. 可以按阶段返回命中结果

这一阶段建议完成：

1. 为 artifact、architecture、entrypoint、build、guard 建立基础匹配规则
2. 输出 `matchedSkills`
3. 输出 `recommendedLoadOrder`
4. 输出 `blockedActions`

成功标准：

1. 对常见仓库能命中正确的基础 Skill
2. 至少能识别 Compose、Dockerfile、Makefile、pnpm、CMake、monorepo

---

## Phase 3：主 Agent 接入

目标：

1. 主 Agent 不再直接依赖旧版模板 Skill
2. 主 Agent 先做项目理解，再给出部署策略

这一阶段建议完成：

1. 主 Agent 接收 `matchedSkills`
2. 主 Agent 按 phase 逐步加载 Skill
3. 主 Agent 输出统一的项目理解结果
4. 结果字段遵循 [runtime-contract.md](/E:/project/repo-auto-deployer/skills-v2/registry/runtime-contract.md)

成功标准：

1. 主 Agent 能给出 `recommendedStrategy`
2. 主 Agent 能给出 `blockedActions`
3. 主 Agent 能给出 `requiresManualReview`

---

## Phase 4：Shadow Agent 接入

目标：

1. Shadow Agent 对主 Agent 做纠偏
2. 减少错误入口和错误项目类型判断

这一阶段建议完成：

1. 给 Shadow Agent 注入主 Agent 的项目理解结果
2. 给 Shadow Agent 注入关键的 guard 和 entrypoint Skill
3. 输出 `reviewStatus`、`missedEvidence`、`wrongAssumptions`

成功标准：

1. 可识别明显漏掉的官方入口
2. 可识别 monorepo 根目录误装
3. 可识别 CLI / 桌面应用误判

---

## Phase 5：Executor 接入

目标：

1. 执行层只执行被批准的策略
2. 执行结果可回流给纠偏链路

这一阶段建议完成：

1. Executor 只接受结构化决策输入
2. Executor 不再私自切换入口
3. Executor 输出构建、启动、健康检查结果

成功标准：

1. 失败能够区分发生在构建、启动还是健康检查
2. 能把结果回传给主 Agent 和 Shadow Agent

---

## Phase 6：逐步替换旧体系

目标：

1. 让 v2 逐步接管分析主线
2. 让旧版模板型 Skill 退到兼容层

这一阶段建议完成：

1. 新任务默认优先走 v2 理解链路
2. 旧版模板逻辑只保留为最后兜底
3. 给旧逻辑增加明确的降级标记

成功标准：

1. 新仓库优先通过 v2 得到部署策略
2. 旧逻辑不再主导项目理解

---

## 推荐实施顺序

如果只能先做最有价值的一小段，建议优先顺序是：

1. Phase 1
2. Phase 2
3. Phase 3

原因很简单：

先让系统“知道有哪些 Skill”，
再让系统“知道该激活哪些 Skill”，
最后才让主 Agent“真正按 Skill 工作”。

---

## 当前不建议一开始就做的事

1. 直接重写全部部署执行逻辑
2. 一开始就做复杂语义解析
3. 一开始就移除全部旧版 Skill
4. 一开始就把所有生态都做满

先把最小闭环跑通，后面再扩展更稳。

