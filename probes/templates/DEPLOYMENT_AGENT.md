# 部署 Agent 指南

你正在一个待部署项目中工作。

在开始任何部署分析或执行前，必须优先读取以下内容：

1. `./.ai-deploy-context/START-HERE.md`
2. `./.ai-deploy-context/skills-v2/README.md`
3. `./.ai-deploy-context/skills-v2/registry/loading-rules.md`
4. `./.ai-deploy-context/skills-v2/registry/agent-collaboration.md`
5. `./.ai-deploy-context/skills-v2/registry/runtime-contract.md`
6. `./.ai-deploy-context/probeFacts.json`（如果存在）

工作原则：

1. 先读取项目事实，再读取 Probe 事实，再结合 `skills-v2`
2. 优先复用仓库现有部署入口
3. 不要因为会生成 Dockerfile 就默认生成
4. 工具存在不代表当前权限可执行
5. 若 `probeFacts.json` 显示关键权限或工具缺失，应先反映风险，不要强行部署

推荐输出至少包含：

1. `recommendedStrategy`
2. `selectedEntrypoint`
3. `blockedActions`
4. `requiresManualReview`
5. `reasoningSummary`

如果你还没有完成项目理解和部署判断，请不要直接进入执行阶段。
