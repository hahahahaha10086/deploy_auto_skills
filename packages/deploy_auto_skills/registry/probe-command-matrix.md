# Skills v2 Probe 命令矩阵

这份文档列出第一版 Probe 建议执行的命令。
目标是提供一套稳定、只读、低风险的探测动作，而不是让 AI 临场发明命令反复试错。

---

## 1. 使用原则

Probe 命令应满足：

1. 默认只读
2. 尽量无副作用
3. 失败可容忍
4. 输出可结构化

Probe 不应默认执行：

1. 安装命令
2. 删除命令
3. 修改系统配置
4. 启停服务

---

## 2. Linux / Ubuntu / CentOS 推荐命令

### 主机信息

1. `uname -s`
2. `uname -m`
3. `cat /etc/os-release`

建议采集：

1. `host.osFamily`
2. `host.distribution`
3. `host.version`
4. `host.architecture`

### Python 相关

1. `python --version`
2. `python3 --version`
3. `pip --version`
4. `pip3 --version`
5. `conda --version`
6. `poetry --version`
7. `uv --version`

建议采集：

1. `tools.python`
2. `tools.conda`
3. `tools.poetry`
4. `tools.uv`
5. `toolVersions.python`

### Node 相关

1. `node --version`
2. `npm --version`
3. `pnpm --version`
4. `yarn --version`
5. `corepack --version`

### Java / Go / Native 相关

1. `java -version`
2. `mvn -version`
3. `gradle --version`
4. `go version`
5. `cmake --version`
6. `make --version`
7. `gcc --version`
8. `clang --version`

### 容器相关

1. `docker --version`
2. `docker compose version`
3. `docker-compose --version`
4. `podman --version`
5. `docker info`

建议采集：

1. `tools.docker`
2. `tools.dockerCompose`
3. `capabilities.canRunContainers`

### 系统能力

1. `systemctl --version`
2. `bash --version`
3. `sh --version`
4. `nvidia-smi`

建议采集：

1. `capabilities.supportsSystemd`
2. `capabilities.supportsBash`
3. `capabilities.hasGpu`

---

## 3. Windows 推荐命令

建议优先用 PowerShell。

### 主机信息

1. `$PSVersionTable.PSVersion.ToString()`
2. `[System.Environment]::OSVersion.VersionString`
3. `(Get-CimInstance Win32_OperatingSystem).Caption`
4. `$env:PROCESSOR_ARCHITECTURE`

### Python 相关

1. `python --version`
2. `py --version`
3. `pip --version`
4. `conda --version`
5. `poetry --version`
6. `uv --version`

### Node 相关

1. `node --version`
2. `npm --version`
3. `pnpm --version`
4. `yarn --version`
5. `corepack --version`

### Java / Go / Native 相关

1. `java -version`
2. `mvn -version`
3. `gradle --version`
4. `go version`
5. `cmake --version`

### 容器与 WSL 相关

1. `docker --version`
2. `docker compose version`
3. `wsl --status`
4. `wsl -l -v`

建议采集：

1. `tools.docker`
2. `tools.dockerCompose`
3. `tools.wsl`
4. `capabilities.supportsPowerShell`

### GPU 相关

1. `nvidia-smi`

---

## 4. 通用判断规则

建议规则如下：

1. 命令执行成功则工具存在
2. 命令不存在或退出码非零则记为不可用
3. 版本解析失败不影响“是否存在”的结论
4. 高成本命令如 `docker info` 应作为补充探测，不是每次必跑

---

## 5. conda 相关特别说明

Probe 不应直接创建环境。

第一版只需要判断：

1. 主机上有没有 `conda`
2. 版本是多少
3. 是否能被当前 shell 直接访问

如果仓库有 `environment.yml` 但 Probe 显示 `conda=false`，应输出兼容性提示，而不是直接试建环境。

---

## 6. Docker 相关特别说明

第一版建议分两步：

1. `docker --version`
2. `docker compose version`

如需进一步确认是否能访问 daemon，再补：

1. `docker info`

这样可以区分：

1. 命令存在但 daemon 不可用
2. 命令不存在
3. Compose 可用或不可用

---

## 7. 输出建议

命令层执行完成后，建议统一映射成：

1. `tools`
2. `toolVersions`
3. `capabilities`
4. `compatibilityHints`

不要让 Agent 直接吃原始命令行文本作为唯一输入。

