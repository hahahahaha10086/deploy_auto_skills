# Skills v2 Probes 目录结构建议

这份文档定义第一版 `probes/` 目录应该如何组织。
目标是让探针脚本具备固定入口、固定输出和固定分类。

---

## 1. 推荐目录结构

```text
probes/
  README.md
  contracts/
    host.json
    toolchain.json
    permissions.json
    combined.json
  scripts/
    detect-host.ps1
    detect-toolchain.ps1
    detect-permissions.ps1
    detect-host.sh
    detect-toolchain.sh
    detect-permissions.sh
  examples/
    host-linux.json
    host-windows.json
    combined-ubuntu.json
```

---

## 2. 目录职责

### `contracts/`

用于描述各探针输出的 JSON 示例或契约文件。

### `scripts/`

用于存放真正执行探测的脚本。

建议：

1. Windows 优先提供 `.ps1`
2. Linux 优先提供 `.sh`
3. 每个脚本尽量只负责一类事实

### `examples/`

用于存放示例输出，便于主 Agent、加载器和测试使用。

---

## 3. 第一批建议的探针脚本

### detect-host

负责输出：

1. `host`
2. 基础 `capabilities`

### detect-toolchain

负责输出：

1. `tools`
2. `toolVersions`

### detect-permissions

负责输出：

1. `permissions`
2. 部分 `compatibilityHints`

---

## 4. 组合方式

第一版不一定要一个大脚本。

更推荐：

1. 分脚本探测
2. 最后由调用方合并成 `probeFacts`

这样更容易：

1. 单独测试
2. 单独调试
3. 单独替换

---

## 5. 命名约定

建议统一：

1. 文件名使用 `detect-*`
2. 输出 JSON 顶层字段名与 `probe-contract.md` 对齐
3. Windows 和 Linux 脚本保持同名语义

