# Skills v2 Probe 权限模型

这份文档定义 Probe 在权限层面应采集什么，以及这些权限事实如何影响部署决策。

---

## 1. 为什么权限也要探测

很多部署失败不是因为工具缺失，而是因为权限不足。

例如：

1. 主机上有 Docker，但当前用户无法访问 Docker daemon
2. 主机上有 Python，但当前目录不可写
3. 系统支持 systemd，但当前用户不能管理服务
4. 主机上有 conda，但当前 shell 无法直接调用

所以权限不是部署执行阶段才处理的事，而应在 Probe 阶段先产出事实。

---

## 2. 权限探测的目标

Probe 不需要做复杂提权，但应尽量回答：

1. 当前用户是否具备基础写权限
2. 当前用户是否可访问容器能力
3. 当前用户是否具备服务管理能力
4. 当前用户是否具备高风险操作前提

---

## 3. 建议采集的权限事实

### filesystem 权限

建议采集：

1. 部署工作目录是否可写
2. 临时目录是否可写
3. 日志目录是否可写

建议输出字段：

1. `permissions.canWriteWorkspace`
2. `permissions.canWriteTemp`
3. `permissions.canWriteLogs`

### container 权限

建议采集：

1. 是否可执行 `docker ps`
2. 是否可访问 Docker daemon
3. 是否可执行 Compose 相关命令

建议输出字段：

1. `permissions.canAccessDockerDaemon`
2. `permissions.canRunCompose`

### service 权限

建议采集：

1. 是否可执行 `systemctl status`
2. 是否具备服务管理权限

建议输出字段：

1. `permissions.canInspectServices`
2. `permissions.canManageServices`

### identity 权限

建议采集：

1. 当前用户是否是管理员 / root
2. 当前用户组是否包含容器相关组
3. 当前运行身份是否受限

建议输出字段：

1. `permissions.isElevated`
2. `permissions.executionIdentity`

---

## 4. 典型影响

这些权限事实会直接影响部署策略：

1. `canAccessDockerDaemon = false`
   不能把 Docker / Compose 作为可执行主路径
2. `canWriteWorkspace = false`
   不能继续自动生成部署产物
3. `canManageServices = false`
   不应默认走 systemd / service 安装路径
4. `isElevated = false`
   需要谨慎处理需要 root 的安装步骤

---

## 5. Probe 阶段只做什么

权限 Probe 只做：

1. 事实确认
2. 能力探测
3. 风险提示

不做：

1. 自动提权
2. 修改 sudoers
3. 自动切换用户
4. 自动放宽权限

---

## 6. 推荐输出示例

```json
{
  "permissions": {
    "executionIdentity": "user",
    "isElevated": false,
    "canWriteWorkspace": true,
    "canWriteTemp": true,
    "canWriteLogs": true,
    "canAccessDockerDaemon": false,
    "canRunCompose": false,
    "canInspectServices": true,
    "canManageServices": false
  }
}
```

---

## 7. 与 Agent 的关系

主 Agent 看到权限事实后，应做的是：

1. 降低不可执行入口的优先级
2. 阻止高权限前提路径
3. 明确提示“环境具备工具但权限不足”

而不是简单地把“工具存在”误判成“路径可执行”。

