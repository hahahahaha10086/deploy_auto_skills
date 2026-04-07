---
name: guard.monorepo-build-first
description: 全局风险守卫：强制在启动 Monorepo 的局部子项目前，先解决其依赖包的 types 声明或全局构建。
category: guard
version: 1.0.0
---

# Skill: guard.monorepo-build-first

## Description

在使用像 Rush, Lerna 或 Turborepo 管理的巨型 Monorepo 体系中，各个子项目包（packages/*）互相通过 \`workspace:*\` 等软链接强耦合。如果你直接顺手跑某个上层应用的 \`npm run dev\`，极有可能遭遇 \`Cannot find module\`（尤其是 Typescript 的 TS2307 错误），即使你确实刚刚跑成功了全局包安装（\`rush install\` 等）。原因在于，未执行源码构建阶段，底层依赖包往往还没有将自身的 \`*.ts\` 编译吐出给其它包引用的 \`dist/index.js\` 及其声明文件 \`*.d.ts\`。

## Trigger Signals

当主 Agent 已经识别出项目包含 `architecture.monorepo` 特征，并且视图顺理成章地将 `install` 直接作为下一步 `dev/start` 的衔接点时，必须触发本守卫。

## Execution Rules

1. **依赖先行编译**：不管在最终部署的脚本链还是临时生成 `docker-compose` 组合命令中，严格插入 `build` 动作。命令链模式应该是 `install` -> `build (哪怕是增量编译)` -> `dev`。
2. **拒绝盲目局部全量**：如果是几十上百个包的体系，试图推荐全集 `build` 会浪费惊人的时间。应主动寻找工具链提供的单包精确构建指令（例如 `rush build --to @your/sub-project`），仅仅将当前要唤醒的服务及其前置链路构建打通。
3. **识别异常退出**：如果在启动热重载（Watch/Dev）服务器时瞬间闪退并伴随大量红色的模块失踪错误，不要反复尝试修复单个代码，请立即意识到这属于底层产物（dist / lib / esm 目录）未在本地环境中物理生成造成的失联。

## Conflict Rules

本守卫作为 `architecture.monorepo` 激活后的必然相伴产物。没有例外。坚决抵制任何以为“装了依赖就能直接飘红跑起来”的天真部署计划。
