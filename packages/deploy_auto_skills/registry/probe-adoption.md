# Skills v2 Probe 接入说明

这份文档描述 Probe 在整体流程里的接入位置。

---

## 1. 推荐顺序

Probe 应在主 Agent 做项目理解前执行。

推荐链路：

1. 扫描仓库，得到 `repositoryFacts`
2. 执行 Probe，得到 `probeFacts`
3. 用 `repositoryFacts + probeFacts` 匹配 Skill
4. 主 Agent 读取命中 Skill，输出部署策略

---

## 2. 为什么 Probe 要先于主 Agent

因为很多判断如果没有主机事实，会变成猜测。

例如：

1. 仓库里有 `environment.yml`，但主机没有 conda
2. 仓库里有 `docker-compose.yaml`，但主机没有 Docker
3. 仓库是 CMake 项目，但主机缺少 `cmake`

这些都应在 Agent 做最终决策前被显式感知。

---

## 3. 推荐落地方式

第一版可以很简单：

1. 用小脚本输出 JSON
2. 主程序读取 JSON
3. 再传给主 Agent

不要求一开始就做复杂守护进程或长期缓存。

---

## 4. 与旧后端的关系

Probe 可以先独立于旧部署主流程存在。

也就是说：

1. 先做独立主机探针
2. 先产出 `probeFacts`
3. 先用于新 v2 分析链路

不要一开始就强耦合进旧的执行器和旧的 skill loader。

---

## 5. 后续可以扩展什么

后续可以扩展：

1. 更细的 Python 生态探针
2. Docker daemon 与 Compose 兼容性探针
3. GPU / CUDA 探针
4. systemd / service 管理探针
5. 私有依赖与网络可达性探针

但第一版不必做满。

