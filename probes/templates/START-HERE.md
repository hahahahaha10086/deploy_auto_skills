# 从这里开始

你现在位于一个待部署项目中。

不要直接开始生成 Dockerfile、不要直接安装依赖、也不要直接启动容器。

请先按下面顺序工作：

## 第一步：读取上下文

优先读取：

1. `./.ai-deploy-context/AGENTS.md`
2. `./.ai-deploy-context/probeFacts.json`（如果存在）
3. `./.ai-deploy-context/skills-v2/README.md`
4. `./.ai-deploy-context/skills-v2/registry/loading-rules.md`
5. `./.ai-deploy-context/skills-v2/registry/runtime-contract.md`

## 第二步：先判断，再执行

你必须先判断：

1. 这是什么类型的项目
2. 它是单服务、多服务、monorepo，还是别的结构
3. 仓库是否已有官方部署入口
4. 当前目标环境是什么
5. 当前主机工具和权限是否允许该入口执行

## 第三步：输出部署判断

在开始执行前，先明确给出：

1. `recommendedStrategy`
2. `selectedEntrypoint`
3. `blockedActions`
4. `requiresManualReview`
5. `reasoningSummary`

## 必须遵守的规则

1. 优先复用仓库已有部署入口
2. 不要因为能生成 Dockerfile 就默认生成
3. 工具存在不代表当前权限可执行
4. 如果 `probeFacts.json` 显示关键权限不足，应先提示风险
5. 如果缺少关键环境条件，不要强行部署

