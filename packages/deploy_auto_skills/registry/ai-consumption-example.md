# Skills v2 与 ProbeFacts 的 AI 消费示例

这份文档演示外部 AI 或主 Agent 拿到 `probeFacts` 和 `skills-v2` 之后，应如何使用这些输入做部署判断。

---

## 1. 输入来源

AI 在进入部署判断前，至少应拿到三类输入：

1. `repositoryFacts`
2. `probeFacts`
3. 命中的 `skills-v2`

---

## 2. 一个最小示例

### repositoryFacts

```json
{
  "files": [
    "docker/docker-compose.yaml",
    "frontend/package.json",
    "pnpm-lock.yaml"
  ],
  "directories": [
    "docker",
    "frontend",
    "backend"
  ]
}
```

### probeFacts

```json
{
  "host": {
    "osFamily": "windows"
  },
  "tools": {
    "docker": true,
    "dockerCompose": true,
    "pnpm": true
  },
  "permissions": {
    "canAccessDockerDaemon": true,
    "canRunCompose": true,
    "canWriteWorkspace": true
  }
}
```

### activeSkills

```json
[
  "artifact.web-service",
  "architecture.multi-service",
  "entrypoint.existing-compose",
  "environment.windows",
  "build.pnpm-workspace",
  "guard.reuse-official-config-first"
]
```

---

## 3. AI 应该怎么想

AI 的正确流程是：

1. 仓库存在官方 Compose
2. 仓库结构是多服务
3. 目标环境是 Windows
4. 主机具备 Docker 与 Compose
5. 当前用户也具备 Docker daemon 访问权限
6. 因此优先复用官方 Compose
7. 不应生成根目录 Dockerfile

---

## 4. 推荐输出

AI 建议输出：

```json
{
  "recommendedStrategy": "reuse_existing_compose",
  "selectedEntrypoint": "docker/docker-compose.yaml",
  "blockedActions": [
    "generate_root_level_dockerfile"
  ],
  "requiresManualReview": false,
  "reasoningSummary": "仓库提供官方 Compose，主机具备容器能力与对应权限，应优先复用现有编排。"
}
```

---

## 5. 一个失败分支示例

如果 `probeFacts` 变成：

```json
{
  "tools": {
    "docker": true,
    "dockerCompose": true
  },
  "permissions": {
    "canAccessDockerDaemon": false,
    "canRunCompose": false
  }
}
```

那么 AI 不应只因为“Docker 已安装”就继续执行 Compose。

此时更合理的输出是：

```json
{
  "recommendedStrategy": "manual_review_only",
  "blockedActions": [
    "run_docker_compose"
  ],
  "requiresManualReview": true,
  "reasoningSummary": "主机已安装 Docker，但当前执行身份无权访问 Docker daemon，Compose 路径不可执行。"
}
```

---

## 6. 核心原则

AI 不应：

1. 只看仓库，不看 Probe
2. 只看工具存在，不看权限
3. 只看语言，不看官方入口

AI 应该：

1. 结合 `repositoryFacts`
2. 结合 `probeFacts`
3. 结合 `skills-v2`
4. 再输出部署策略

