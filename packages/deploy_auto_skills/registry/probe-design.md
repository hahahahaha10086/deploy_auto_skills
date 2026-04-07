# Skills v2 Probe 设计

这份文档定义 `skills-v2` 体系里的 `Probe` 概念。
`Probe` 不是 Skill，也不是 Agent。它负责采集环境事实，为后续 Skill 判断和 Agent 决策提供可靠输入。

---

## 1. 为什么需要 Probe

仅靠 AI 读取仓库，无法知道部署主机是否真的具备所需条件。

例如：

1. 机器上是否安装了 `conda`
2. 是否有 `python` / `node` / `java`
3. 是否有 `docker` / `docker compose`
4. 当前到底是 Windows、Linux、WSL 还是具体发行版
5. 是否存在 `cmake`、`make`、`gcc`

这些都不应由 AI 猜测，而应由 Probe 采集。

---

## 2. Probe 的职责边界

### Probe 负责

1. 采集主机和运行环境事实
2. 采集工具、运行时、包管理器是否存在
3. 采集版本信息
4. 采集容器、GPU、systemd 等能力信息
5. 采集关键权限事实

### Probe 不负责

1. 决定项目应该怎么部署
2. 决定是否必须走 conda / Docker / systemd
3. 直接修改部署策略
4. 替代 Skill 或 Agent 做结论判断

一句话：

`Probe 产事实，Skill 给规则，Agent 做决策。`

---

## 3. 推荐 Probe 分类

### host probe

负责采集基础主机事实：

1. 操作系统
2. 发行版
3. 版本
4. CPU 架构
5. shell 能力

### toolchain probe

负责采集工具链事实：

1. `docker`
2. `docker compose`
3. `python`
4. `pip`
5. `conda`
6. `node`
7. `npm`
8. `pnpm`
9. `java`
10. `mvn`
11. `gradle`
12. `go`
13. `cmake`
14. `make`

### capability probe

负责采集能力事实：

1. 是否可运行容器
2. 是否支持 systemd
3. 是否有 GPU
4. 是否可访问 Docker daemon
5. 是否支持 PowerShell / bash

### project-affinity probe

这类 Probe 用于把仓库线索与主机线索拼起来做初步兼容性检查，但不做最终决策。

例如：

1. 仓库有 `environment.yml`，主机是否有 `conda`
2. 仓库有 `docker-compose.yaml`，主机是否有 `docker compose`
3. 仓库有 `CMakeLists.txt`，主机是否有 `cmake`

---

## 4. Probe 与 Skill 的配合方式

例如：

1. `environment.ubuntu` 需要知道主机是否真的是 Ubuntu
2. `build.cmake` 需要知道主机是否有 `cmake`
3. `entrypoint.existing-compose` 需要知道主机是否有 Docker/Compose
4. Python 项目若命中 conda 线索，需要 Probe 告诉 Agent 当前主机有没有 conda

所以 Skill 读取的不是“虚构环境”，而是 Probe 产出的事实。

---

## 5. 典型输出字段

Probe 的输出建议包括：

1. `host`
2. `tools`
3. `capabilities`
4. `toolVersions`
5. `permissions`
6. `compatibilityHints`

例如：

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
    "node": "20.11.1",
    "pnpm": "9.0.0"
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
    "canAccessDockerDaemon": false
  },
  "compatibilityHints": [
    "repo_has_environment_yml_but_conda_missing",
    "repo_has_compose_and_compose_is_available"
  ]
}
```

---

## 6. 第一版建议先探测什么

第一版建议只做高价值字段：

1. 系统类型
2. 发行版
3. `docker`
4. `docker compose`
5. `python`
6. `conda`
7. `node`
8. `pnpm`
9. `java`
10. `go`
11. `cmake`
12. `make`
13. 基础写权限
14. Docker daemon 访问权限

这已经足够支撑很多基础部署判断。

---

## 7. 先不要做什么

一开始不建议做：

1. 探测所有系统包
2. 自动修复环境
3. 自动安装缺失依赖
4. 复杂权限提升
5. 自动申请管理员权限

先把“知道主机有什么”做好，再谈自动补环境。
