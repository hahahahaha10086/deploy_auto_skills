# Skills v2 Probe 脚本输出约定

这份文档定义第一版 Probe 脚本应该输出什么格式。

---

## 1. 总体原则

每个 Probe 脚本都应：

1. 输出 JSON
2. 可单独执行
3. 输出字段稳定
4. 允许部分字段缺失

不要输出：

1. 夹杂解释性长文本
2. 彩色日志
3. 与契约无关的调试输出

---

## 2. `detect-host`

建议输出：

```json
{
  "host": {
    "osFamily": "linux",
    "distribution": "ubuntu",
    "version": "22.04",
    "architecture": "x86_64"
  },
  "capabilities": {
    "supportsSystemd": true,
    "supportsBash": true,
    "supportsPowerShell": false
  }
}
```

---

## 3. `detect-toolchain`

建议输出：

```json
{
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
    "docker": "26.1.1",
    "python": "3.11.8",
    "node": "20.11.1"
  }
}
```

---

## 4. `detect-permissions`

建议输出：

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
  },
  "compatibilityHints": [
    "docker_installed_but_daemon_access_denied"
  ]
}
```

---

## 5. 合并后的 `probeFacts`

调用方合并后，建议得到：

```json
{
  "host": {},
  "tools": {},
  "toolVersions": {},
  "capabilities": {},
  "permissions": {},
  "compatibilityHints": []
}
```

---

## 6. 失败处理约定

若某探针脚本失败：

1. 尽量仍返回合法 JSON
2. 将失败项标记为缺失或不可用
3. 不要直接导致整个 Probe 流程崩溃

例如：

```json
{
  "tools": {
    "conda": false
  },
  "compatibilityHints": [
    "conda_probe_failed_or_missing"
  ]
}
```

