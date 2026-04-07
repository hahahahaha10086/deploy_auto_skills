# Skills v2 加载器设计

这份文档描述 `skills-v2` 在程序侧应如何被发现、解析、筛选和组装。
目标不是一开始就做很重的语义引擎，而是先实现一套稳定、可扩展、可验证的最小加载器。

---

## 1. 设计目标

加载器至少要解决四件事：

1. 发现有哪些 Skill
2. 读取每个 Skill 的基础元数据
3. 按阶段挑出本轮需要激活的 Skill
4. 将激活结果提供给主 Agent、Shadow Agent、Executor

不要求第一版就做到：

1. 完整理解全部 Markdown 语义
2. 自动推理所有章节内容
3. 复杂向量检索

---

## 2. 输入与输出

### 输入

加载器的输入建议包括：

1. `skillsRoot`
2. `repositoryFacts`
3. `probeFacts`
4. `phase`
5. `requestedRoles`

示例：

```json
{
  "skillsRoot": "skills-v2",
  "repositoryFacts": {
    "files": ["docker/docker-compose.yaml", "frontend/package.json", "pnpm-lock.yaml"],
    "directories": ["docker", "frontend", "backend"],
    "readmeSnippets": ["Quick Start", "Docker Compose"],
    "packageManagers": ["pnpm"]
  },
  "probeFacts": {
    "host": {
      "osFamily": "linux",
      "distribution": "ubuntu"
    },
    "tools": {
      "docker": true,
      "dockerCompose": true,
      "conda": false
    }
  },
  "phase": "entrypoint",
  "requestedRoles": ["main-agent", "shadow-agent"]
}
```

### 输出

加载器输出建议包括：

1. `availableSkills`
2. `matchedSkills`
3. `blockedSkills`
4. `recommendedLoadOrder`

---

## 3. 发现机制

### 3.1 目录发现

第一版建议直接按目录扫描：

1. 找到 `skills-v2/` 下所有 `SKILL.md`
2. 同时识别 `registry/` 下的规范文档
3. 以目录路径推断类别

例如：

1. `skills-v2/foundations/artifact/.../SKILL.md`
2. `skills-v2/ecosystems/.../SKILL.md`
3. `skills-v2/playbooks/.../SKILL.md`

### 3.2 名称发现

对于每个 `SKILL.md`：

1. 读取 frontmatter 中的 `name`
2. 读取 frontmatter 中的 `description`
3. 记录物理路径
4. 记录推断类别

---

## 4. 解析层次

建议分两层解析：

### Level 1：元数据解析

只解析：

1. `name`
2. `description`
3. `category`
4. `path`

这层用于：

1. 建目录索引
2. 快速决定候选 Skill
3. 避免一次性读太多内容

### Level 2：正文解析

在 Skill 被命中后，再读取正文并按章节切分：

1. `Purpose`
2. `Trigger Signals`
3. `Required Evidence`
4. `Analysis Steps`
5. `Decision Hints`
6. `Risk Guards`
7. `Stop Conditions`
8. `Output Hints`
9. `Related Skills`

这层用于：

1. 给 Agent 提供细化指引
2. 提供程序可提取的半结构化片段

---

## 5. 匹配机制

第一版建议采用“规则命中 + 人工可解释”的方式。

### 5.1 基础规则

示例：

1. 若发现 `docker-compose.yml`、`docker-compose.yaml`、`compose.yml`、`compose.yaml`，则命中 `entrypoint.existing-compose`
2. 若发现 `pnpm-lock.yaml` 或 `pnpm-workspace.yaml`，则命中 `build.pnpm-workspace`
3. 若发现 `CMakeLists.txt`，则命中 `build.cmake`
4. 若发现 `apps/`、`packages/`、`rush.json`、`turbo.json`，则提高 `architecture.monorepo` 候选优先级
5. 若 `probeFacts.host.distribution == ubuntu`，则提高 `environment.ubuntu` 候选优先级
6. 若仓库有 `environment.yml` 且 `probeFacts.tools.conda == false`，则增加兼容性风险提示

### 5.2 多阶段筛选

不要一次性把全部 Skill 都塞给 Agent。

建议：

1. Phase 1 只给 artifact
2. Phase 2 再给 architecture
3. Phase 3 再给 entrypoint
4. Phase 4 再给 environment
5. Phase 5 再给 build 和 ecosystem
6. Phase 6 再给 guard
7. Phase 7 再给 playbook

### 5.3 冲突处理

冲突按以下优先级处理：

1. `guard`
2. `entrypoint`
3. `artifact`
4. `architecture`
5. `build`
6. `ecosystem`
7. `playbook`

这条规则应与 [loading-rules.md](/E:/project/repo-auto-deployer/skills-v2/registry/loading-rules.md) 保持一致。

---

## 6. 推荐数据模型

### SkillMeta

```json
{
  "name": "entrypoint.existing-compose",
  "description": "用于识别仓库中已有的 Compose 编排入口。",
  "category": "entrypoint",
  "path": "skills-v2/foundations/entrypoint/existing-compose/SKILL.md"
}
```

### SkillMatch

```json
{
  "name": "entrypoint.existing-compose",
  "matched": true,
  "confidence": "high",
  "reasons": [
    "found docker/docker-compose.yaml"
  ]
}
```

### SkillBundle

```json
{
  "phase": "entrypoint",
  "matchedSkills": [
    "entrypoint.existing-compose",
    "entrypoint.readme"
  ],
  "blockedSkills": [],
  "recommendedLoadOrder": [
    "entrypoint.existing-compose",
    "entrypoint.readme"
  ]
}
```

---

## 7. Agent 使用方式

### 主 Agent

主 Agent 需要：

1. 元数据索引
2. 当前阶段命中的 Skill 列表
3. 命中 Skill 的正文片段

### Shadow Agent

Shadow Agent 需要：

1. 主 Agent 已激活的 Skill
2. 被忽略但命中的 Skill
3. 关键 guard 和 entrypoint Skill

### Executor

Executor 通常不需要读取全部 Skill 正文。

Executor 最少需要：

1. `recommendedStrategy`
2. `selectedEntrypoint`
3. `blockedActions`
4. `requiresManualReview`

---

## 8. 第一版实现建议

建议先做一个最小版本：

1. 扫描所有 `SKILL.md`
2. 解析 frontmatter
3. 建一个内存索引
4. 根据文件名和目录名做规则命中
5. 按 phase 返回命中 Skill

这一版先解决“知道该加载谁”，不要急着解决“复杂语义提取”。

---

## 9. 暂缓事项

这些能力可以后置：

1. 向量检索
2. LLM 自动总结所有 Skill
3. Skill 之间复杂依赖图
4. 自动生成全部规则

先把最小版做稳，比一开始做复杂更重要。
