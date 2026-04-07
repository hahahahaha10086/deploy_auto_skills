# Probes

这里存放第一版部署探针脚本。

当前先提供 Windows / PowerShell 版本：

1. `scripts/detect-host.ps1`
2. `scripts/detect-toolchain.ps1`
3. `scripts/detect-permissions.ps1`
4. `scripts/combine-probes.ps1`
5. `scripts/run-probes.ps1`
6. `scripts/package-deployment-context.ps1`

这些脚本的目标是：

1. 采集主机事实
2. 采集工具链事实
3. 采集权限与执行能力事实

约束：

1. 默认输出 JSON
2. 尽量保持低风险
3. 不负责安装依赖
4. 不负责直接部署项目

推荐用法：

```powershell
powershell -ExecutionPolicy Bypass -File .\probes\scripts\detect-host.ps1
powershell -ExecutionPolicy Bypass -File .\probes\scripts\detect-toolchain.ps1
powershell -ExecutionPolicy Bypass -File .\probes\scripts\detect-permissions.ps1 -WorkspacePath .
powershell -ExecutionPolicy Bypass -File .\probes\scripts\combine-probes.ps1 -WorkspacePath . -LogsPath .\runtime
powershell -ExecutionPolicy Bypass -File .\probes\scripts\run-probes.ps1 -WorkspacePath . -LogsPath .\runtime -OutputPath .\runtime\probeFacts.json
powershell -ExecutionPolicy Bypass -File .\probes\scripts\package-deployment-context.ps1 -TargetProjectPath 'E:\target\repo'
```

`combine-probes.ps1` 会依次调用前三个脚本，并输出统一的 `probeFacts` JSON。
`run-probes.ps1` 会调用 `combine-probes.ps1`，并可选择把结果写入文件。
`package-deployment-context.ps1` 会把 `skills-v2`、`probes`、`probeFacts.json`、`AGENTS.md` 和 `START-HERE.md` 一起复制到目标项目的 `.ai-deploy-context/` 中。
