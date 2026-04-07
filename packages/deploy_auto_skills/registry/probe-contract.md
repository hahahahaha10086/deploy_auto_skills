# Skills v2 Probe 输出契约

这份文档定义 Probe 输出给 Skill 与 Agent 的最小结构。

---

## 1. 最小结构

```json
{
  "host": {
    "osFamily": "linux",
    "distribution": "ubuntu",
    "version": "22.04",
    "architecture": "x86_64"
  },
  "tools": {
    "docker": true,
    "dockerCompose": true,
    "python": true,
    "conda": false,
    "node": true,
    "pnpm": true,
    "cmake": false
  },
  "toolVersions": {
    "python": "3.11.8",
    "node": "20.11.1"
  },
  "capabilities": {
    "canRunContainers": true,
    "supportsSystemd": true,
    "hasGpu": false
  },
  "permissions": {
    "executionIdentity": "user",
    "isElevated": false,
    "canWriteWorkspace": true,
    "canAccessDockerDaemon": false,
    "canRunCompose": false
  },
  "compatibilityHints": []
}
```

---

## 2. 字段说明

### host

用于描述主机基础信息。

建议字段：

1. `osFamily`
2. `distribution`
3. `version`
4. `architecture`

### tools

用于描述工具是否存在。

值建议统一用布尔值。

### toolVersions

用于描述关键工具版本。

如果某工具不存在，可以省略或置空。

### capabilities

用于描述更高层能力。

建议字段：

1. `canRunContainers`
2. `supportsSystemd`
3. `hasGpu`
4. `supportsPowerShell`
5. `supportsBash`

### permissions

用于描述当前执行身份与关键权限能力。

建议字段：

1. `executionIdentity`
2. `isElevated`
3. `canWriteWorkspace`
4. `canWriteTemp`
5. `canWriteLogs`
6. `canAccessDockerDaemon`
7. `canRunCompose`
8. `canInspectServices`
9. `canManageServices`

### compatibilityHints

用于描述探针层已经能明确发现的兼容性提示，但不是最终部署决策。

例如：

1. `repo_has_environment_yml_but_conda_missing`
2. `repo_has_compose_and_compose_is_available`
3. `repo_is_cmake_based_but_cmake_missing`

---

## 3. 与主 Agent 的关系

主 Agent 不应直接猜环境。

主 Agent 应读取：

1. `repositoryFacts`
2. `probeFacts`
3. `activeSkills`

然后再输出最终部署策略。

---

## 4. 与 Skill 的关系

环境 Skill 和构建 Skill 可直接消费 Probe 输出。

例如：

1. `environment.windows` 读取 `host.osFamily`
2. `environment.ubuntu` 读取 `host.distribution`
3. `build.cmake` 读取 `tools.cmake`
4. Python 生态 Skill 可读取 `tools.conda`

---

## 5. 最小可用要求

如果第一版 Probe 能稳定输出以下内容，就已经可用：

1. `host.osFamily`
2. `host.distribution`
3. `tools.docker`
4. `tools.dockerCompose`
5. `tools.python`
6. `tools.conda`
7. `tools.node`
8. `tools.pnpm`
9. `tools.cmake`
10. `capabilities.canRunContainers`
11. `permissions.canWriteWorkspace`
12. `permissions.canAccessDockerDaemon`
