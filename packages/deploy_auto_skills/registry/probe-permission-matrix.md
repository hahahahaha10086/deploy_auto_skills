# Skills v2 权限探测命令矩阵

这份文档列出第一版可考虑的权限探测命令。
这些命令仍然应尽量保持只读与低风险。

---

## 1. Linux / Ubuntu / CentOS

### 当前身份

1. `id -u`
2. `id -un`
3. `id -Gn`

建议采集：

1. `permissions.executionIdentity`
2. `permissions.isElevated`

### 工作目录写权限

建议方式：

1. 判断部署工作目录是否存在
2. 使用写权限检查，而不是创建文件为默认做法

可选命令：

1. `test -w <path>`

建议采集：

1. `permissions.canWriteWorkspace`
2. `permissions.canWriteLogs`

### Docker 权限

1. `docker ps`
2. `docker compose version`

建议采集：

1. `permissions.canAccessDockerDaemon`
2. `permissions.canRunCompose`

### systemd 权限

1. `systemctl status`
2. `systemctl is-system-running`

建议采集：

1. `permissions.canInspectServices`
2. `capabilities.supportsSystemd`

注意：

1. 可查看不代表可管理
2. `systemctl start` 不应在 Probe 阶段执行

---

## 2. Windows

### 当前身份

1. `[Security.Principal.WindowsIdentity]::GetCurrent().Name`
2. `(New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)`

建议采集：

1. `permissions.executionIdentity`
2. `permissions.isElevated`

### 工作目录写权限

可通过目录属性检查或尝试只读权限判断。

建议输出：

1. `permissions.canWriteWorkspace`
2. `permissions.canWriteLogs`

### Docker 权限

1. `docker ps`
2. `docker compose version`

建议采集：

1. `permissions.canAccessDockerDaemon`
2. `permissions.canRunCompose`

### 服务管理权限

Windows 下如果后续涉及服务安装或管理，应单独评估管理员权限。

Probe 第一版只需要回答：

1. 当前是否具备管理员权限

---

## 3. 解释规则

建议规则：

1. 命令存在但执行失败，要区分“工具不存在”和“权限不足”
2. Docker 最常见的是“命令存在但 daemon 无权限访问”
3. systemd 最常见的是“系统支持，但当前用户无管理权限”

---

## 4. 与 Probe 输出的映射

这些命令建议映射到：

1. `permissions`
2. `capabilities`
3. `compatibilityHints`

例如：

1. `docker_installed_but_daemon_access_denied`
2. `workspace_not_writable`
3. `systemd_present_but_service_management_unavailable`

