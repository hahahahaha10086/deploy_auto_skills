# 模块职责划分 v1

## 1. 文档目标

本文档定义系统核心模块、模块边界、职责范围、输入输出与协作关系，确保后续实现时职责清晰、依赖合理。

## 2. 模块总览

核心模块划分如下：

- 仓库接入模块
- 任务编排模块
- 项目分析模块
- 部署策略模块
- 配置生成模块
- AI 决策模块
- 部署执行模块
- 健康检查模块
- 失败诊断模块
- 日志审计模块
- 管理后台模块
- 规则模板模块
- 系统设置模块

## 3. 模块职责

### 3.1 仓库接入模块

职责：

- 接收 GitHub 仓库地址
- 校验输入参数
- 支持 branch、可选凭证等扩展字段
- 创建部署任务
- 准备工作目录

输入：

- repo URL
- branch
- optional auth info

输出：

- task id
- normalized repo metadata
- workspace path

不负责：

- 技术栈识别
- Docker 执行
- AI 推理

### 3.2 任务编排模块

职责：

- 驱动任务状态机
- 串联各阶段模块执行
- 处理超时、中断、重试
- 汇总阶段结果

输入：

- task id
- task config

输出：

- task status transitions
- execution summary

不负责：

- 直接生成配置文件
- 直接分析日志根因

### 3.3 项目分析模块

职责：

- 扫描仓库目录结构
- 识别关键文件和技术栈
- 推断包管理器、启动命令、构建命令
- 识别已有 Dockerfile / compose
- 形成项目画像

输入：

- workspace path

输出：

- project profile
- detected files
- confidence notes

不负责：

- 最终部署策略裁决
- 实际容器执行

### 3.4 部署策略模块

职责：

- 根据项目画像选择部署路线
- 判断复用已有配置还是重新生成
- 调用 AI 获取辅助判断
- 输出策略和风险标签

输入：

- project profile
- repository facts
- optional AI recommendation

输出：

- deployment strategy
- risk list
- confidence score

### 3.5 配置生成模块

职责：

- 复用已有 Dockerfile / compose
- 基于规则模板生成基础容器配置
- 接收 AI 补充建议
- 落盘生成产物

输入：

- deployment strategy
- project profile
- template rules
- optional AI hints

输出：

- Dockerfile
- docker-compose.yml
- generation metadata

### 3.6 AI 决策模块

职责：

- 处理仓库策略推理
- 处理失败日志诊断
- 输出结构化结论

输入：

- summarized repository facts
- summarized logs
- current config

输出：

- structured decision
- confidence
- recommended next action

约束：

- 不直接执行命令
- 不直接更新状态机

### 3.7 部署执行模块

职责：

- 运行构建命令
- 运行 compose 启动命令
- 记录执行结果
- 收集执行期日志

输入：

- generated artifacts
- task runtime config

输出：

- build result
- startup result
- runtime metadata

### 3.8 健康检查模块

职责：

- 检查容器状态
- 检查端口和 HTTP 响应
- 输出部署可用性结论

输入：

- running containers
- expected ports/endpoints

输出：

- health result
- reachable endpoints

### 3.9 失败诊断模块

职责：

- 汇总失败阶段信息
- 归类错误
- 调用 AI 做根因诊断
- 生成修复建议和重试决策

输入：

- failed stage
- logs
- config artifacts
- project profile

输出：

- error category
- root cause hypothesis
- retry recommendation
- manual review recommendation

### 3.10 日志审计模块

职责：

- 记录阶段日志
- 保留命令输出摘要
- 保留 AI 决策摘要
- 保留用户操作审计

输入：

- task events
- command output
- AI traces

输出：

- searchable logs
- audit timeline

### 3.11 管理后台模块

职责：

- 提供操作入口与结果展示
- 展示任务状态、日志、AI 决策
- 支持手动重试、清理、查看产物

输入：

- API responses

输出：

- user operations
- visualization of task lifecycle

### 3.12 规则模板模块

职责：

- 管理不同技术栈的 Dockerfile 模板
- 管理 compose 片段
- 支持版本化维护
- 为配置生成模块提供规则输入

输入：

- template definitions

输出：

- resolved templates

### 3.13 系统设置模块

职责：

- 管理默认超时、重试次数、端口范围
- 管理 AI provider 配置
- 管理运行目录和清理策略

输入：

- system config changes

输出：

- effective runtime config

## 4. 模块协作链路

推荐模块调用顺序：

1. 仓库接入模块
2. 任务编排模块
3. 项目分析模块
4. 部署策略模块
5. 配置生成模块
6. 部署执行模块
7. 健康检查模块
8. 失败诊断模块
9. 日志审计模块贯穿全链路
10. 管理后台模块负责展示和操作

## 5. 单一职责约束

- 项目分析模块只负责识别事实，不直接改配置
- AI 模块只负责推理，不直接执行命令
- 执行模块只负责执行，不做复杂业务判断
- 编排模块负责阶段推进，不直接做底层文件读写逻辑

## 6. 后续演进建议

- 部署策略模块可逐步沉淀为规则引擎
- AI 决策模块后续可拆为策略 Agent 与诊断 Agent
- 日志审计模块后续可接入统一检索与统计面板
