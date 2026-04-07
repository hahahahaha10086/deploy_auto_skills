# 接口文档设计 v1

## 1. 文档目标

本文档定义 MVP 阶段的核心 API 设计，包括任务创建、任务查询、日志查看、重试、清理、模板管理与系统设置接口。

## 2. 设计约定

- API 风格：REST
- 数据格式：JSON
- 时间格式：ISO 8601
- 主键 ID：字符串 UUID
- 长任务采用异步任务模型

基础响应结构建议：

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

错误响应建议：

```json
{
  "success": false,
  "data": null,
  "error": {
    "code": "INVALID_REPO_URL",
    "message": "Repository URL is invalid."
  }
}
```

## 3. 任务相关接口

### 3.1 创建部署任务

`POST /api/tasks`

请求示例：

```json
{
  "repoUrl": "https://github.com/example/project",
  "branch": "main",
  "autoRetry": true
}
```

响应示例：

```json
{
  "success": true,
  "data": {
    "taskId": "task_001",
    "status": "queued"
  },
  "error": null
}
```

### 3.2 查询任务列表

`GET /api/tasks`

查询参数建议：

- `status`
- `keyword`
- `page`
- `pageSize`

响应字段建议：

- taskId
- repoUrl
- status
- createdAt
- updatedAt
- summary

### 3.3 查询任务详情

`GET /api/tasks/:taskId`

响应字段建议：

- taskId
- repoUrl
- branch
- status
- currentStage
- projectProfile
- strategy
- artifacts
- result
- retryCount
- createdAt
- updatedAt

### 3.4 重试任务

`POST /api/tasks/:taskId/retry`

请求示例：

```json
{
  "mode": "auto"
}
```

### 3.5 清理任务环境

`DELETE /api/tasks/:taskId/runtime`

响应字段建议：

- taskId
- cleaned
- cleanedResources

## 4. 日志相关接口

### 4.1 查询任务日志摘要

`GET /api/tasks/:taskId/logs`

查询参数建议：

- `type=task|build|compose|healthcheck|all`

### 4.2 查询任务时间线

`GET /api/tasks/:taskId/timeline`

返回：

- stage
- status
- startedAt
- endedAt
- note

## 5. AI 决策相关接口

### 5.1 查询 AI 策略决策

`GET /api/tasks/:taskId/ai/strategy`

返回字段建议：

- projectType
- recommendedStrategy
- startCommand
- exposedPort
- requiredServices
- risks
- confidence

### 5.2 查询 AI 失败诊断

`GET /api/tasks/:taskId/ai/diagnosis`

返回字段建议：

- errorCategory
- rootCause
- suggestions
- shouldRetry
- confidence

## 6. 规则模板接口

### 6.1 查询模板列表

`GET /api/templates`

### 6.2 查询模板详情

`GET /api/templates/:templateId`

### 6.3 创建模板

`POST /api/templates`

### 6.4 更新模板

`PUT /api/templates/:templateId`

### 6.5 删除模板

`DELETE /api/templates/:templateId`

模板字段建议：

- templateId
- name
- language
- framework
- type
- version
- content
- enabled

## 7. 系统设置接口

### 7.1 查询系统设置

`GET /api/settings`

### 7.2 更新系统设置

`PUT /api/settings`

设置项建议：

- maxRetryCount
- defaultTaskTimeoutSeconds
- workspaceRoot
- artifactRoot
- logRoot
- aiProvider
- aiModel
- portRangeStart
- portRangeEnd

## 8. 统计接口

### 8.1 查询系统概览

`GET /api/stats/overview`

返回字段建议：

- totalTasks
- successTasks
- failedTasks
- runningTasks
- successRate

### 8.2 查询错误分类统计

`GET /api/stats/errors`

## 9. 错误码建议

- `INVALID_REPO_URL`
- `TASK_NOT_FOUND`
- `TASK_ALREADY_RUNNING`
- `CLONE_FAILED`
- `ANALYSIS_FAILED`
- `STRATEGY_FAILED`
- `GENERATION_FAILED`
- `BUILD_FAILED`
- `START_FAILED`
- `HEALTHCHECK_FAILED`
- `CLEANUP_FAILED`
- `INTERNAL_ERROR`

## 10. 版本建议

MVP 阶段建议直接使用 `/api`，在需要兼容升级后再引入 `/api/v1`。
