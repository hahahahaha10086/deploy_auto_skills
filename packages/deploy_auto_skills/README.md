# Skills v2

这是新的 Markdown Skill 体系根目录。

设计原则：

1. 与旧版 `backend/skillpacks/` 明确分离
2. Skill 是帮助 Agent 做项目理解与部署决策的知识文档
3. Skill 不是 Dockerfile、Compose 或部署脚本模板
4. 优先复用仓库已有部署入口，生成部署产物只作为最后兜底

当前第一批 Skill 包含：

1. 交付物识别：`web-service`、`cli-tool`、`desktop-app`
2. 架构识别：`multi-service`、`monorepo`
3. 入口识别：`existing-compose`、`script`、`makefile`
4. 环境识别：`windows`、`linux`、`ubuntu`、`centos`、`wsl`
5. 构建链识别：`pnpm-workspace`、`cmake`
6. 风险约束：`reuse-official-config-first`、`no-root-install-in-monorepo`、`no-cli-as-web-service`、`no-desktop-auto-deploy`
7. 作战手册：`project-understanding`、`deployment-decision`、`failure-correction`

推荐加载顺序：

1. `foundations/artifact/`
2. `foundations/architecture/`
3. `foundations/entrypoint/`
4. `foundations/environment/`
5. `foundations/build/`
6. `foundations/guard/`
7. `playbooks/`

推荐先阅读：

1. `registry/catalog.md`
2. `registry/loading-rules.md`
3. `registry/agent-collaboration.md`
4. `registry/skill-document-schema.md`
5. `registry/runtime-contract.md`
6. `registry/loader-design.md`
7. `registry/adoption-roadmap.md`
8. `registry/probe-design.md`
9. `registry/probe-contract.md`
10. `registry/probe-adoption.md`
11. `registry/probe-command-matrix.md`
12. `registry/probe-safety-rules.md`
13. `registry/probe-permission-model.md`
14. `registry/probe-permission-matrix.md`
15. `registry/probe-layout.md`
16. `registry/probe-script-contracts.md`
17. `registry/ai-consumption-example.md`
