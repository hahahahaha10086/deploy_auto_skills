# Skills v2 加载规则

这份文档定义 `skills-v2` 被 Agent 加载和组合的顺序。

目标：

1. 避免 Agent 随意挑 Skill
2. 避免先入为主的单语言推断
3. 让风险约束 Skill 在关键节点能真正生效

---

## 1. 总原则

Skill 的加载不是“找到一个最像的就用”，而是“按阶段加载一组 Skill，逐步收敛结论”。

推荐流程：

1. 先判断交付物类型
2. 再判断架构类型
3. 再判断部署入口
4. 再判断目标环境
5. 再判断构建链和生态
6. 再加载风险约束
7. 最后进入 playbook

---

## 2. 推荐加载顺序

### Phase 1：交付物识别

优先加载：

1. `artifact.web-service`
2. `artifact.cli-tool`
3. `artifact.desktop-app`

这一阶段要先回答：

1. 这是服务、工具、桌面程序还是别的东西
2. 是否适合继续进入自动部署流程

### Phase 2：架构识别

优先加载：

1. `architecture.multi-service`
2. `architecture.monorepo`

这一阶段要回答：

1. 根目录是不是可运行单元
2. 是否存在多个服务或多个应用

### Phase 3：入口识别

优先加载：

1. `entrypoint.existing-compose`
2. `entrypoint.existing-dockerfile`
3. `entrypoint.makefile`
4. `entrypoint.script`
5. `entrypoint.readme`
6. `entrypoint.ci-workflow`

这一阶段要回答：

1. 仓库作者已经提供了什么入口
2. 官方部署入口的优先级应该如何排序

### Phase 4：目标环境识别

优先加载：

1. `environment.windows`
2. `environment.linux`
3. `environment.ubuntu`
4. `environment.centos`
5. `environment.wsl`

这一阶段要回答：

1. 当前目标部署环境是什么
2. 当前入口与目标环境是否兼容
3. 是否存在系统级差异导致的自动化风险

### Phase 5：构建链与生态识别

优先加载：

1. `build.pnpm-workspace`
2. `build.cmake`
3. `ecosystem.nextjs`
4. `ecosystem.fastapi`
5. `ecosystem.langgraph`
6. `ecosystem.spring`
7. `ecosystem.php-monolith`

这一阶段要回答：

1. 不该用错什么构建方式
2. 该生态下常见的误判是什么

### Phase 6：风险约束

优先加载：

1. `guard.reuse-official-config-first`
2. `guard.no-root-install-in-monorepo`
3. `guard.no-cli-as-web-service`
4. `guard.no-desktop-auto-deploy`

这一阶段要回答：

1. 哪些动作必须被阻止
2. 哪些条件下必须停止自动化

### Phase 7：Playbook

最后加载：

1. `playbooks.project-understanding`
2. `playbooks.deployment-decision`
3. `playbooks.failure-correction`

这一阶段负责把前面所有 Skill 的结果组织成统一工作流。

---

## 3. 解析优先级

当不同 Skill 的结论发生冲突时，建议按以下优先级处理：

1. `guard`
2. `entrypoint`
3. `artifact`
4. `architecture`
5. `environment`
6. `build`
7. `ecosystem`
8. `playbook`

解释：

1. 风险约束优先于一切功能性判断
2. 官方入口优先于语言或生态推断
3. 交付物类型优先于默认部署幻想
4. 目标环境会约束入口与执行方式
5. 生态增强不能覆盖官方入口和风险约束

---

## 4. 冲突处理规则

### 4.1 CLI 与 Web 服务冲突

若同时命中 `artifact.cli-tool` 和 `artifact.web-service`：

1. 优先检查 README 的主要交互方式
2. 若主要是命令参数和一次性执行，优先 CLI
3. 若主要是端口、站点、API，可继续 Web 服务判定

### 4.2 单服务与多服务冲突

若同时出现单服务倾向和多服务线索：

1. 只要存在 Compose 或多个运行角色，就优先按多服务处理
2. 多服务不能退化成单服务模板

### 4.3 官方入口与生成路径冲突

若已经发现官方 Compose / Dockerfile / Makefile / 脚本：

1. 优先复用
2. 只有在官方入口不可用且证据充分时，才允许兜底生成

---

## 5. 主 Agent 输出要求

加载完 Skill 后，主 Agent 应输出一份结构化理解结果，至少包含：

1. `artifactType`
2. `architectureType`
3. `entrypointCandidates`
4. `targetEnvironment`
5. `environmentCompatibility`
6. `activeSkills`
7. `blockedActions`
8. `recommendedStrategy`
9. `allowGeneratedArtifacts`
10. `requiresManualReview`
11. `risks`

---

## 6. 不允许的行为

在 v2 体系下，以下行为应视为违规：

1. 未扫描子目录就宣称“没有 Compose”
2. 未识别交付物类型就直接生成 Dockerfile
3. monorepo 中直接在根目录执行安装
4. 把桌面程序直接塞进 Web 部署流程
5. 把 CLI 工具直接走 HTTP 健康检查流程
6. 在目标环境未确认时直接套用特定系统命令
