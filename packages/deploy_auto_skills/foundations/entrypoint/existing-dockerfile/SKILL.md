---
name: entrypoint.existing-dockerfile
description: 用于识别并优先复用仓库已有的 Dockerfile，包括根目录或子目录中的官方 Dockerfile。适用于单服务项目、子项目独立构建项目，以及仓库作者已经明确给出容器化入口的场景。
category: entrypoint
version: 1.0.0
---

# Skill: entrypoint.existing-dockerfile

## Purpose

帮助 Agent 把仓库已有 Dockerfile 视为高优先级部署证据，而不是默认自行生成新的 Dockerfile。

## Trigger Signals

1. 仓库存在 `Dockerfile`
2. 子目录中存在独立运行单元对应的 Dockerfile
3. README、脚本或 Compose 明确引用该 Dockerfile

## Required Evidence

1. 根目录或高价值子目录中的 `Dockerfile`
2. README、脚本或 Compose 对 Dockerfile 的引用
3. Dockerfile 所属运行单元与目录上下文
4. Dockerfile 依赖的锁文件、环境变量和构建上下文

## Analysis Steps

1. 先扫描根目录 Dockerfile
2. 再扫描高价值子目录中的 Dockerfile
3. 再判断 Dockerfile 是否属于目标运行单元
4. 再检查 README 或 Compose 是否引用该 Dockerfile

## Decision Hints

1. 若仓库已有官方 Dockerfile，优先复用其构建逻辑
2. 若是多服务项目，应先确认 Dockerfile 属于哪个服务
3. 不要在已有 Dockerfile 时立即退回到通用生成模板

## Risk Guards

1. 不要把测试或示例 Dockerfile 当成生产入口
2. 不要默认根目录 Dockerfile 就代表最终部署单元

## Stop Conditions

1. 存在多个 Dockerfile，但无法判断主次关系
2. Dockerfile 明显只用于开发或测试

## Output Hints

1. `entrypointCandidates` 应包含 Dockerfile 路径、来源和适用运行单元
2. `recommendedStrategy` 应倾向 `reuse_existing_dockerfile`
3. `risks` 应记录多 Dockerfile 冲突或开发用 Dockerfile 风险

## Related Skills

1. `entrypoint.existing-compose`
2. `build.pnpm-workspace`
3. `guard.reuse-official-config-first`
