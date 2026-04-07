---
name: foundation.env-probe
description: 在部署分析开始前，通过现成的探测脚本采集目标机器的真实环境信息（OS、工具链、权限），避免 AI 凭空猜测宿主机状态。
category: foundation
version: 1.0.0
---

# Skill: foundation.env-probe

## Purpose

在任何部署规划开始之前，先取得目标机器的**真实环境快照**。
脚本已内置于本 skill 的 `scripts/` 目录，无需额外安装。

## Trigger Conditions

满足以下任意一条时，必须先运行探测再继续：

1. 用户提到"部署到某台机器"或"服务器上跑"
2. 用户描述的运行环境不明确（未说明 OS、Docker 版本、有无 GPU 等）
3. 部署目标不是当前开发机（不是本地跑，是远程或生产机）
4. 用户要求生成 Dockerfile / docker-compose 等产物

## How to Run

告知用户在**目标机器**（部署目标，非本地开发机）上执行以下命令：

```powershell
# 进入 skill 的 scripts 目录
cd <项目根>/.agents/skills/foundations/env-probe/scripts

# 运行主脚本，将结果保存到文件
.\run-probes.ps1 -WorkspacePath <项目路径> -OutputPath probe-result.json

# 然后把 probe-result.json 的内容粘贴给 AI
```

如果目标机器就是当前机器，路径可简化：
```powershell
.\run-probes.ps1 -WorkspacePath . -OutputPath probe-result.json
```

## Output Schema

脚本输出一个 JSON，结构如下：

```json
{
  "host": {
    "osFamily": "windows | linux",
    "distribution": "Windows 11 Pro / Ubuntu 22.04 ...",
    "version": "...",
    "architecture": "amd64 | arm64"
  },
  "tools": {
    "docker": true,
    "dockerCompose": true,
    "python": false,
    "conda": false,
    "node": true,
    "pnpm": false,
    "java": false,
    "go": false,
    "cmake": false
  },
  "toolVersions": {
    "docker": "Docker version 24.0.5",
    "node": "v20.11.0"
  },
  "capabilities": {
    "supportsSystemd": false,
    "supportsBash": true,
    "supportsPowerShell": true,
    "hasGpu": false
  },
  "permissions": {
    "executionIdentity": "MACHINE\\user",
    "isElevated": false,
    "canWriteWorkspace": true,
    "canWriteTemp": true,
    "canWriteLogs": true,
    "canAccessDockerDaemon": true,
    "canRunCompose": true,
    "canManageServices": false
  },
  "compatibilityHints": []
}
```

## Decision Rules

拿到 probe 结果后，按以下规则推导部署方案：

### Docker 可用性
- `tools.docker = true` 且 `permissions.canAccessDockerDaemon = true` → 可以使用容器化部署
- `tools.docker = true` 且 `permissions.canAccessDockerDaemon = false` → Docker 已安装但无权访问 daemon，需提示用户加入 docker 组或以管理员运行
- `tools.docker = false` → 不能使用 Docker，必须改为原生进程部署

### Compose
- `tools.dockerCompose = true` 且 `permissions.canRunCompose = true` → 可以使用 `docker compose`
- 否则 → 只能生成单容器 `docker run` 命令，不生成 compose 文件

### 权限
- `permissions.isElevated = false` → 生成的脚本不要依赖需要管理员权限的操作
- `permissions.canWriteWorkspace = false` → 警告用户当前用户无法写入项目目录

### GPU
- `capabilities.hasGpu = true` → 可以在 Dockerfile 中添加 `nvidia` runtime 配置
- 否则 → 不添加 GPU 相关配置

### compatibilityHints
- `docker_installed_but_daemon_access_denied` → 权限问题，建议固定提示
- `workspace_not_writable` → 工作区无写权限，需提前告知用户
- `probe_execution_failed:<script>` → 该子探测失败，对应字段数据不可信，需要手动确认

## Output Hints

分析完 probe 结果后，在回复中明确标注：

1. `environment.confirmed = true` — 表示本次分析基于真实探测数据而非假设
2. 列出影响决策的关键字段（如 `tools.docker`、`permissions.canAccessDockerDaemon`）
3. 如果有 `compatibilityHints`，逐条说明含义和建议操作

## Scripts Reference

| 文件 | 作用 |
|------|------|
| `run-probes.ps1` | 主入口，调用其余脚本并输出合并后的 JSON |
| `combine-probes.ps1` | 负责运行三个子探测并合并结果 |
| `detect-host.ps1` | 探测 OS、架构、GPU |
| `detect-toolchain.ps1` | 探测 Docker、Node、Python 等工具链版本 |
| `detect-permissions.ps1` | 探测文件写权限、Docker daemon 访问权限 |

## Related Skills

1. `foundation.artifact-generator`
2. `ecosystem.fastapi`
3. `ecosystem.nextjs`
