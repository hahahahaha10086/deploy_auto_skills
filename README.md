# Aegis Deploy

`Aegis Deploy` 是一个面向多 Agent 运行时的项目部署技能库与安装工具。

当前 Phase 1 的目标是先把这套技能库做成一个最小可运行的 CLI：

1. `doctor`
   探测当前运行时的技能目录
2. `index`
   从 `skills-v2/` 生成结构化技能索引
3. `install`
   按 target 把技能库安装到对应运行时目录

## 当前支持的 target

1. `antigravity`
   默认安装到项目级 `.agents/skills/aegis-deploy/`
2. `codex`
   默认安装到用户级 `.codex/skills/aegis-deploy/`
   当前环境中若未找到 `.codex/skills`，则回退到 `.agents/skills`

## 用法

```powershell
npm run doctor
npm run index
npm run install:antigravity
npm run install:codex
```

也可以直接运行：

```powershell
node .\src\index.js install --target antigravity
node .\src\index.js install --target codex
```

## 当前限制

1. 现在的 `install` 还是第一版骨架
2. `antigravity` 和 `codex` 目录规则是基于当前已确认环境做的最小实现
3. `claude-code` 和 Google 侧适配尚未接入
4. 还没有完整 lint / matcher / scheduler 执行链
