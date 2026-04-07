# Skills v2 文档结构规范

这份文档定义 `skills-v2` 中单个 `SKILL.md` 应遵循的固定结构。
目标是让 Skill 既适合 Agent 阅读，也适合后续程序化解析。

---

## 1. 总原则

每个 `SKILL.md` 都应保持：

1. 中文为主
2. 结构稳定
3. 内容精简
4. 强调判断与约束，而不是模板产物

Skill 文档不应变成：

1. 大段背景介绍
2. 框架百科
3. Dockerfile 模板集合
4. 与当前 Skill 无关的项目说明

---

## 2. 推荐结构

每个 `SKILL.md` 建议包含以下部分：

1. Frontmatter
2. `# Skill: ...`
3. `## Purpose`
4. `## Trigger Signals`
5. `## Required Evidence`
6. `## Analysis Steps`
7. `## Decision Hints`
8. `## Risk Guards`
9. `## Stop Conditions`
10. `## Output Hints`
11. `## Related Skills`

不是所有 Skill 都必须把每一节写得一样长，但章节名尽量保持一致。

---

## 3. Frontmatter 要求

推荐最少包含：

```md
---
name: entrypoint.existing-compose
description: 用于识别仓库中已有的 Compose 编排入口，并指导 Agent 优先复用官方编排方式。
---
```

要求：

1. `name` 必填，使用稳定命名
2. `description` 必填，直接描述用途
3. 不在 frontmatter 中堆积复杂字段

---

## 4. 各章节含义

### Purpose

说明这个 Skill 解决什么问题。

应该写：

1. 帮助 Agent 判断什么
2. 在什么阶段使用
3. 解决哪类误判

不应该写：

1. 宏大叙事
2. 技术历史
3. 无关的生态介绍

### Trigger Signals

说明这个 Skill 何时应被激活。

可以包括：

1. 文件名
2. 目录名
3. README 关键词
4. 配置特征
5. 代码结构特征

### Required Evidence

说明激活后必须再去看哪些证据。

例如：

1. `docker/`
2. `deploy/`
3. `README`
4. `Makefile`
5. `package.json`

### Analysis Steps

说明 Agent 应按什么顺序继续分析。

这部分要强调顺序，不要只列概念。

### Decision Hints

说明命中这个 Skill 后，对部署决策有哪些影响。

例如：

1. 是否优先复用官方入口
2. 是否禁止根目录安装
3. 是否应转人工复核

### Risk Guards

说明最容易犯的错是什么。

这部分要尽量明确、可执行。

### Stop Conditions

说明什么情况下不该继续自动部署。

### Output Hints

说明这个 Skill 建议向主 Agent 输出哪些结论字段。

### Related Skills

说明它常与哪些 Skill 搭配使用。

---

## 5. 不同类别 Skill 的侧重点

### artifact 类

重点放在：

1. 交付物类型识别
2. 是否适合自动部署
3. 是否应该转人工

### architecture 类

重点放在：

1. 目录结构
2. 可运行单元位置
3. 根目录是否可直接运行

### entrypoint 类

重点放在：

1. 官方入口识别
2. 优先级排序
3. 复用策略

### build 类

重点放在：

1. 构建链
2. 包管理器
3. 常见误装路径

### environment 类

重点放在：

1. 目标部署环境识别
2. 系统差异约束
3. 环境兼容性与风险

### ecosystem 类

重点放在：

1. 生态特有线索
2. 常见陷阱
3. 对通用判断的修正

### guard 类

重点放在：

1. 禁止行为
2. 拦截条件
3. 风险升级条件

### playbook 类

重点放在：

1. 多个 Skill 之间如何组织
2. 阶段性工作流
3. 输出契约

---

## 6. 长度建议

单个 `SKILL.md` 建议：

1. 够用即可
2. 不重复其它 Skill 内容
3. 保持高信噪比

如果某个 Skill 已经变成大量生态知识堆积，优先拆到配套的 `references/`。

---

## 7. 推荐模板

```md
---
name: guard.example
description: 用于阻止某类高风险自动化行为。
---

# Skill: guard.example

## Purpose

说明这个 Skill 解决的问题。

## Trigger Signals

1. 信号 A
2. 信号 B

## Required Evidence

1. 证据 A
2. 证据 B

## Analysis Steps

1. 先做什么
2. 再做什么

## Decision Hints

1. 对主 Agent 的建议 A
2. 对部署决策的建议 B

## Risk Guards

1. 要避免的错误 A
2. 要避免的错误 B

## Stop Conditions

1. 停止条件 A
2. 停止条件 B

## Output Hints

1. 建议输出字段 A
2. 建议输出字段 B

## Related Skills

1. `other.skill-a`
2. `other.skill-b`
```
