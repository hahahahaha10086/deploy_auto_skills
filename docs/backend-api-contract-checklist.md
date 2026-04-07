# Backend API Contract Checklist

> 文档版本：v1.1
> 创建时间：2026-04-02
> 来源代码：`src/server.js`、`src/routes/tasks.js`
> 目的：冻结当前 Node.js 后端 API 契约，作为 FastAPI 迁移对照基线

---

## 1. 使用说明

这份文档记录的是当前后端真实暴露的 API 契约，不是目标设计稿。

迁移到 FastAPI 时，默认要求：

1. 路径不变
2. 方法不变
3. query 参数名不变
4. 请求体字段名不变
5. 成功响应结构不变
6. 错误结构不变
7. 状态码不变
8. 关键错误码不变

如果某项必须调整，需要在迁移时单独标注“兼容性变更”。

---

## 2. 通用响应格式

### 2.1 成功响应

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

### 2.2 失败响应

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "ERROR_CODE",
    "message": "Readable message"
  }
}
```

### 2.3 通用要求

1. 响应头为 `Content-Type: application/json; charset=utf-8`
2. 未命中路由时返回 `404`
3. JSON 体解析失败时返回 `400`

---

## 3. 全局接口

### 3.1 `GET /health`

用途：

- 服务健康检查

请求体：

- 无

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "service": "repo-auto-deployer-api",
    "status": "ok",
    "phase": "phase-2b"
  },
  "error": null
}
```

备注：

- `phase` 当前是硬编码值，迁移时默认保持一致，除非明确决定调整

### 3.2 全局 404

未命中任何路由时：

- 状态码：`404`

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "NOT_FOUND",
    "message": "Route does not exist."
  }
}
```

### 3.3 全局无效请求元数据

当 `request.url` 或 `request.method` 缺失时：

- 状态码：`400`

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Missing request metadata."
  }
}
```

---

## 4. Tasks API

### 4.1 `POST /api/tasks`

用途：

- 创建单个任务

请求体：

- JSON 对象
- 具体字段由 `createTask(payload)` 校验

成功响应：

- 状态码：`201`

```json
{
  "success": true,
  "data": {
    "taskId": "task_xxx",
    "status": "queued",
    "runtime": {}
  },
  "error": null
}
```

失败响应：

- `400 INVALID_JSON`：`Request body must be valid JSON.`
- `createTask` 返回的业务错误：状态码、错误码、错误文案透传
- `500 INTERNAL_ERROR`：`Unexpected server error.`

兼容要求：

1. 创建成功后会立即调度任务流水线
2. 返回字段必须包含 `taskId`、`status`、`runtime`

### 4.2 `POST /api/tasks/batch`

用途：

- 批量创建任务

请求体：

- JSON 对象
- 具体字段由 `createBatchTasks(payload)` 校验

成功响应：

- 状态码：`201`

```json
{
  "success": true,
  "data": {
    "batchId": "batch_xxx",
    "total": 2,
    "items": [
      {
        "taskId": "task_1",
        "batchId": "batch_xxx",
        "status": "queued",
        "repoUrl": "https://example.com/repo.git"
      }
    ]
  },
  "error": null
}
```

失败响应：

- `400 INVALID_JSON`：`Request body must be valid JSON.`
- `createBatchTasks` 返回的业务错误：状态码、错误码、错误文案透传
- `500 INTERNAL_ERROR`：`Unexpected server error.`

兼容要求：

1. 创建成功后会立即调度批量任务流水线
2. `items` 中的字段保持为 `taskId`、`batchId`、`status`、`repoUrl`

### 4.3 `GET /api/tasks`

用途：

- 查询任务列表

Query 参数：

- `status`：可选
- `keyword`：可选
- `batchId`：可选

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "items": [],
    "total": 0
  },
  "error": null
}
```

失败响应：

- `400 INVALID_STATUS`：`Status filter is not recognized.`

兼容要求：

1. `status` 校验依赖当前系统的 `validStatuses`
2. 返回结构固定为 `{ items, total }`

### 4.4 `GET /api/tasks/:taskId`

用途：

- 获取单个任务详情

成功响应：

- 状态码：`200`
- `data` 为完整任务对象

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`

### 4.5 `DELETE /api/tasks/:taskId`

用途：

- 删除任务

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "taskId": "task_xxx",
    "deleted": true
  },
  "error": null
}
```

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`
- `409 TASK_STILL_RUNNING`：`Cannot delete a task that is still running. Stop it first.`
- `500 INTERNAL_ERROR`：`Unexpected server error.`

### 4.6 `POST /api/tasks/:taskId/retry`

用途：

- 重试任务

请求体：

```json
{
  "mode": "auto"
}
```

备注：

- `mode` 可省略，默认值为 `"auto"`

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "taskId": "task_xxx",
    "status": "queued",
    "retryCount": 1
  },
  "error": null
}
```

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`
- `409 TASK_ALREADY_RUNNING`：`Task cannot be retried while it is still running.`
- `400 INVALID_JSON`：`Request body must be valid JSON.`
- `500 RETRY_FAILED`：消息透传异常信息

兼容要求：

1. 重试成功后会再次调度任务流水线
2. 返回字段固定为 `taskId`、`status`、`retryCount`

### 4.7 `GET /api/tasks/:taskId/ai/diagnosis`

用途：

- 获取任务失败诊断

行为：

1. 若 `task.result?.diagnosis` 已存在，直接返回
2. 否则调用 `diagnoseTaskFailure(task, task.summary)`

成功响应：

- 状态码：`200`
- `data` 为诊断对象，结构由诊断模块决定

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`

### 4.8 `GET /api/tasks/:taskId/ai/strategy`

用途：

- 获取任务策略

成功响应：

- 状态码：`200`
- 若任务已有 `strategy`，直接返回
- 否则返回默认兜底策略

默认兜底响应：

```json
{
  "success": true,
  "data": {
    "source": "rules",
    "mode": "unknown",
    "nextAction": "manual_review",
    "risks": [
      "Strategy is not available until repository analysis has completed."
    ]
  },
  "error": null
}
```

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`

### 4.9 `GET /api/tasks/:taskId/logs`

用途：

- 获取任务日志

Query 参数：

- `type`：可选，默认 `all`

成功响应：

- 状态码：`200`
- `data` 由 `readTaskLogs(task, type)` 返回

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`
- `400 INVALID_LOG_TYPE`：`Log type is not recognized.`

兼容要求：

1. 当 `type` 缺失时，默认按 `all` 处理
2. 类型校验依赖 `isSupportedLogType`

### 4.10 `GET /api/tasks/:taskId/timeline`

用途：

- 获取任务时间线

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "items": []
  },
  "error": null
}
```

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`

兼容要求：

- 当时间线为空时返回 `items: []`

### 4.11 `GET /api/tasks/:taskId/runtime/status`

用途：

- 获取 runtime 状态

成功响应：

- 状态码：`200`
- `data` 由 `getRuntimeStatus(task)` 返回

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`

### 4.12 `GET /api/tasks/:taskId/runtime/stats`

用途：

- 获取 runtime 资源统计

成功响应：

- 状态码：`200`
- `data` 由 `getRuntimeStats(task)` 返回

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`

### 4.13 `GET /api/tasks/:taskId/runtime/logs`

用途：

- 获取 runtime 日志

成功响应：

- 状态码：`200`
- `data` 由 `getRuntimeLogs(task)` 返回

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`

### 4.14 `POST /api/tasks/:taskId/runtime/start`

用途：

- 启动 runtime

请求体：

- 无

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "taskId": "task_xxx",
    "action": "started"
  },
  "error": null
}
```

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`
- `500 RUNTIME_ERROR`：消息来自捕获到的异常，若无异常对象则为 `Failed to start.`

### 4.15 `POST /api/tasks/:taskId/runtime/stop`

用途：

- 停止 runtime

请求体：

- 无

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "taskId": "task_xxx",
    "action": "stopped"
  },
  "error": null
}
```

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`
- `500 RUNTIME_ERROR`：消息来自捕获到的异常，若无异常对象则为 `Failed to stop.`

### 4.16 `DELETE /api/tasks/:taskId/runtime`

用途：

- 清理 runtime

成功响应：

- 状态码：`200`
- 返回结构为：

```json
{
  "success": true,
  "data": {
    "taskId": "task_xxx"
  },
  "error": null
}
```

备注：

- 实际响应会在 `taskId` 基础上展开 `cleanupResult` 的字段

失败响应：

- `404 TASK_NOT_FOUND`：`Task does not exist.`
- `500 CLEANUP_FAILED`：消息来自异常或 `Unexpected cleanup failure.`

### 4.17 `/api/tasks/:taskId/*` 未命中子路由

当任务存在，但子路径不匹配已知规则时：

- 状态码：`404`

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "NOT_FOUND",
    "message": "Route does not exist."
  }
}
```

---

## 5. Batches API

### 5.1 `GET /api/batches/:batchId`

用途：

- 获取批次详情

成功响应：

- 状态码：`200`
- `data` 为 `getBatch(batchId)` 返回值

失败响应：

- `404 BATCH_NOT_FOUND`：`Batch does not exist.`

---

## 6. Stats API

### 6.1 `GET /api/stats/batches`

用途：

- 获取批次统计

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "items": []
  },
  "error": null
}
```

### 6.2 `GET /api/stats/overview`

用途：

- 获取任务总览统计

成功响应：

- 状态码：`200`
- `data` 为 `getTaskStats()` 返回值

### 6.3 `GET /api/stats/errors`

用途：

- 获取错误统计

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "items": []
  },
  "error": null
}
```

---

## 7. Settings API

### 7.1 `GET /api/settings`

用途：

- 读取系统设置

成功响应：

- 状态码：`200`
- `data` 为 `getSystemSettings()` 返回值

### 7.2 `PUT /api/settings`

用途：

- 更新系统设置

请求体：

- JSON 对象
- 具体字段由 `updateSystemSettings(payload)` 校验

成功响应：

- 状态码：`200`
- `data` 为更新后的设置对象

失败响应：

- `400 INVALID_JSON`：`Request body must be valid JSON.`
- `400 INVALID_SETTING`：`Setting {fieldName} is invalid.`
- `500 INTERNAL_ERROR`：`Unexpected server error.`

兼容要求：

- `INVALID_SETTING` 的 message 需要包含具体字段名

---

## 8. Skills API

### 8.1 `GET /api/skills`

用途：

- 查询技能列表

Query 参数：

- `language`：可选，默认空字符串
- `category`：可选，默认空字符串

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "items": []
  },
  "error": null
}
```

### 8.2 `POST /api/skills`

用途：

- 创建技能

请求体：

- JSON 对象
- 具体字段由 `createSkill(payload)` 校验

成功响应：

- 状态码：`201`
- `data` 为新建 skill 对象

失败响应：

- `400 INVALID_JSON`：`Request body must be valid JSON.`
- `409 SKILL_ALREADY_EXISTS`：`Skill already exists.`
- `500 INTERNAL_ERROR`：`Unexpected server error.`

### 8.3 `GET /api/skills/:skillId`

用途：

- 获取 skill 详情

成功响应：

- 状态码：`200`
- `data` 为 skill 对象

失败响应：

- `404 SKILL_NOT_FOUND`：`Skill does not exist.`

### 8.4 `PUT /api/skills/:skillId`

用途：

- 更新 skill

请求体：

- JSON 对象

成功响应：

- 状态码：`200`
- `data` 为更新后的 skill 对象

失败响应：

- `404 SKILL_NOT_FOUND`：`Skill does not exist.`
- `400 INVALID_JSON`：`Request body must be valid JSON.`
- `500 INTERNAL_ERROR`：`Unexpected server error.`

### 8.5 `DELETE /api/skills/:skillId`

用途：

- 删除 skill

成功响应：

- 状态码：`200`

```json
{
  "success": true,
  "data": {
    "skillId": "skill_xxx",
    "deleted": true
  },
  "error": null
}
```

失败响应：

- `404 SKILL_NOT_FOUND`：`Skill does not exist.`

### 8.6 `/api/skills/:skillId` 空 ID 特例

当路径命中 `/api/skills/` 但解析不出 `skillId` 时：

- 状态码：`404`

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "SKILL_NOT_FOUND",
    "message": "Skill does not exist."
  }
}
```

---

## 9. 通用错误码清单

当前代码中已出现的错误码包括：

| 错误码 | 常见状态码 | 说明 |
|---|---|---|
| `INVALID_REQUEST` | `400` | 请求缺少基础元数据 |
| `INVALID_JSON` | `400` | 请求体不是合法 JSON |
| `INVALID_STATUS` | `400` | 任务状态过滤条件非法 |
| `INVALID_LOG_TYPE` | `400` | 日志类型非法 |
| `INVALID_SETTING` | `400` | 设置字段校验失败 |
| `NOT_FOUND` | `404` | 路由不存在 |
| `TASK_NOT_FOUND` | `404` | 任务不存在 |
| `BATCH_NOT_FOUND` | `404` | 批次不存在 |
| `SKILL_NOT_FOUND` | `404` | skill 不存在 |
| `SKILL_ALREADY_EXISTS` | `409` | skill 重复创建 |
| `TASK_ALREADY_RUNNING` | `409` | 任务运行中不可重试 |
| `TASK_STILL_RUNNING` | `409` | 任务运行中不可删除 |
| `RETRY_FAILED` | `500` | 重试任务失败 |
| `RUNTIME_START_FAILED` | `409` | runtime 启动失败 |
| `RUNTIME_STOP_FAILED` | `409` | runtime 停止失败 |
| `RUNTIME_CLEANUP_FAILED` | `409` | runtime 清理失败 |
| `DEPLOYMENT_COMMAND_FAILED` | `500` | Docker / Compose 执行失败 |
| `DEPLOYMENT_STATUS_FAILED` | `500` | runtime 状态读取失败 |
| `SERVICE_NOT_RUNNING` | `500` | 服务未进入运行态 |
| `SERVICE_HEALTH_TIMEOUT` | `500` | 服务在超时窗口内未稳定就绪 |
| `INTERNAL_ERROR` | `500` | 通用内部错误 |

---

## 10. 迁移验收清单

FastAPI 迁移后，至少逐项核验：

- [ ] 所有路径保持一致
- [ ] 所有 HTTP 方法保持一致
- [ ] 通用响应包装保持一致
- [ ] `201` / `200` / `400` / `404` / `409` / `500` 状态码语义一致
- [ ] `taskId`、`batchId`、`skillId` 等关键字段命名一致
- [ ] 默认兜底策略接口保持一致
- [ ] 未命中任务子路由时仍返回 `NOT_FOUND`
- [ ] 错误码和主要错误文案一致
- [ ] 前端实际调用的 query 参数行为一致

---

## 11. 开放项

以下内容在当前代码中由下游模块决定，本清单只冻结路由层语义，不冻结内部对象的完整字段结构：

1. 任务对象完整字段
2. 批次对象完整字段
3. 设置对象完整字段
4. skill 对象完整字段
5. runtime status / stats / logs 的详细结构
6. 失败诊断对象的详细结构

这些字段如果要进一步冻结，需要继续补一份“响应样例采集”文档或从模块实现中再向下展开。

---

## 12. 当前 FastAPI 实现补充

以下内容不是原始 Node.js 基线，而是当前 FastAPI 实现已经落地的补充契约。后续如果以前端切主为目标，应以这一节和实际代码一起继续收口。

### 12.1 runtime 相关错误码

当前 Python 后端已经把 runtime / deployment 错误拆得更细，不再统一归到 `RUNTIME_ERROR` 或 `CLEANUP_FAILED`：

1. `RUNTIME_START_FAILED`
2. `RUNTIME_STOP_FAILED`
3. `RUNTIME_CLEANUP_FAILED`
4. `DEPLOYMENT_COMMAND_FAILED`
5. `DEPLOYMENT_STATUS_FAILED`
6. `SERVICE_NOT_RUNNING`
7. `SERVICE_HEALTH_TIMEOUT`

这意味着切主前需要决定：

1. 前端是否继续只识别旧错误码
2. 还是同步接受更细颗粒度的错误码

### 12.2 runtime 返回结构

当前 Python 后端的 runtime 查询接口已经接入真实 Docker 数据，`runtime/status` 返回中可能出现以下字段：

1. `state`
2. `serviceState`
3. `serviceHealth`
4. `services`
5. `error`

`runtime/logs` 和 `runtime/stats` 也已经不再只是占位返回，而是会读取真实 Docker CLI 输出。

### 12.3 后续动作建议

如果要继续冻结最终对外契约，建议下一步补一份“FastAPI 实际响应样例”文档，分别采集：

1. 成功部署中的 runtime status
2. 部署失败时的 runtime status / logs
3. `runtime/start` / `runtime/stop` / `runtime cleanup` 的成功与失败样例
