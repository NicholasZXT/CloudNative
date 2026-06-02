# 目录

[TOC]


# 介绍

基于 WSL2 + Kind + Ansible 搭建云原生大数据平台。



## 阶段 0：WSL2 硬件边界配置

> **目标**：在 Windows 宿主机层面划定 WSL2 虚拟机的资源上限，防止大数据组件触发 OOM Kill 导致集群丢失。此阶段必须在 Ansible 介入前完成。

| 主要任务          | 说明                                                       | 交付物/验证标准                           |
| :---------------- | :--------------------------------------------------------- | :---------------------------------------- |
| 编辑 `.wslconfig` | 配置 `memory`, `processors`, `swap`, `localhostForwarding` | 文件存在于 `%UserProfile%\.wslconfig`     |
| 重启 WSL2 实例    | 执行 `wsl --shutdown` 使硬件边界生效                       | `wsl -l -v` 显示 Running 且资源限制已应用 |
| 进入 WSL2 验证    | 确认分发版正常启动，资源符合预期                           | `free -h`, `nproc` 输出与配置一致         |

## 阶段 1：Bootstrap 与 OS/容器运行时初始化

> **目标**：完成 Ansible 自举，并将 WSL2 从"裸发行版"转变为"生产就绪的容器宿主"。本阶段分为手动引导和 Ansible 接管两部分。

| 主要任务           | 执行方式              | 说明                                               | 交付物/验证标准                            |
| :----------------- | :-------------------- | :------------------------------------------------- | :----------------------------------------- |
| 安装前置依赖       | 🖐️ 手动 / bootstrap.sh | 安装 `python3-pip`, `ansible`, `docker-ce`         | Ansible CLI 可用，Docker 二进制存在        |
| 系统内核调优       | 🤖 Ansible             | `vm.max_map_count`, `vm.swappiness` 等 sysctl 参数 | `/etc/sysctl.d/99-bigdata.conf` 存在且生效 |
| 文件描述符配置     | 🤖 Ansible             | `nofile`, `nproc`, `memlock` limits 配置           | `ulimit -a` 输出符合大数据组件要求         |
| Docker Daemon 配置 | 🤖 Ansible             | `daemon.json` 渲染、日志轮转、存储驱动             | Docker 服务 active，配置变更自动重启       |
| 用户组与目录准备   | 🤖 Ansible             | docker 用户组、数据挂载点创建                      | 免 sudo docker，`/opt/bigdata/data*` 就绪  |

## 阶段 2：Kind 集群创建

> **目标**：在 WSL2 内部署多节点 Kind 集群，并完成 kubeconfig 的双侧同步。

| 主要任务            | 执行方式  | 说明                                              | 交付物/验证标准                                |
| :------------------ | :-------- | :------------------------------------------------ | :--------------------------------------------- |
| 安装 K8s CLI 工具链 | 🤖 Ansible | 指定版本的 `kind`, `kubectl`, `helm`              | 各工具版本匹配且可执行                         |
| 生成集群配置        | 🤖 Ansible | 模板化 `kind-config.yaml`（含端口映射、数据挂载） | 配置文件内容与变量一致                         |
| 创建 Kind 集群      | 🤖 Ansible | `kind create cluster` 并等待就绪                  | 所有节点 Ready，API Server 可达                |
| 导出 kubeconfig     | 🤖 Ansible | 复制到 WSL2 内及 Windows 侧 `.kube/config`        | Windows PowerShell 中 `kubectl get nodes` 正常 |

## 阶段 3：K8s 基础设施组件部署

> **目标**：为大数据应用提供必要的集群级基础能力，包括镜像缓存、网络入口和本地持久化。

| 主要任务                  | 执行方式         | 说明                                 | 交付物/验证标准                           |
| :------------------------ | :--------------- | :----------------------------------- | :---------------------------------------- |
| 部署 Local Registry       | 🤖 Ansible        | Docker Container + Kind 节点对接配置 | `localhost:5000` 可推送/拉取镜像          |
| 部署 MetalLB              | 🤖 Ansible (Helm) | LoadBalancer IP 地址池配置           | Service 可获得真实 Cluster IP             |
| 部署 Ingress Controller   | 🤖 Ansible (Helm) | Nginx Ingress，绑定 hostPort 80/443  | `curl http://localhost` 返回 Ingress 响应 |
| 部署 Metrics Server       | 🤖 Ansible (Helm) | HPA 与资源监控依赖                   | `kubectl top nodes/pods` 有数据           |
| 配置 Local PV Provisioner | 🤖 Ansible        | 基于 extraMounts 创建 PV             | PVC 可绑定到 `/var/bigdata` 路径          |

## 阶段 4：验证与冒烟测试

> **目标**：端到端验证集群可用性，输出访问信息，确保环境可交付给大数据组件部署。

| 主要任务           | 执行方式  | 说明                                         | 交付物/验证标准        |
| :----------------- | :-------- | :------------------------------------------- | :--------------------- |
| 节点就绪检查       | 🤖 Ansible | Wait for all nodes Ready                     | 超时内全部 Ready       |
| 基础设施连通性验证 | 🤖 Ansible | Registry pull、MetalLB IP 分配、Ingress 响应 | 三项检查均通过         |
| 访问信息输出       | 🤖 Ansible | Debug 打印 Dashboard/Registry/Ingress 地址   | 控制台输出完整访问指引 |
| Windows 侧联通验证 | 🖐️ 手动    | PowerShell kubectl + 浏览器访问              | 双侧均可正常操作集群   |

------

## 执行约束备忘

- **控制节点**：全程在 WSL2 内部执行，`connection: local`
- **阶段边界**：Phase 0 纯手动；Phase 1 含手动 Bootstrap；Phase 2-4 全 Ansible
- **幂等性**：Phase 1-4 的 Ansible Playbook 必须支持重复执行而不产生副作用
- **Teardown 对等**：每个阶段的创建逻辑都应有对应的清理逻辑（后续实施时补充）



## 项目结构

```text
k8s-bigdata-lab/
├── wslconfig.ini               # Phase 0: wsl硬件配置
├── bootstrap.sh                # Phase 1: 手动引导脚本（装 Ansible + Docker CE）
├── ansible/
│   ├── inventory/
│   │   └── local.ini           # 仅含 localhost ansible_connection=local
│   ├── group_vars/
│   │   └── all.yml             # 全局变量：版本号、端口、路径等
│   ├── roles/
│   │   ├── wsl2-tuning/        # Phase 1: sysctl, limits, 用户组, 目录
│   │   ├── docker-engine/      # Phase 1: daemon.json, service state
│   │   ├── kind-cluster/       # Phase 2: CLI工具, kind-config, 集群创建, kubeconfig同步
│   │   ├── k8s-infra/          # Phase 3: Registry, MetalLB, Ingress, Metrics, LocalPV
│   │   └── cluster-validate/   # Phase 4: 冒烟测试, 访问信息输出
│   ├── playbooks/
│   │   ├── phase1-init.yml     # 编排 wsl2-tuning + docker-engine
│   │   ├── phase2-kind.yml     # 编排 kind-cluster
│   │   ├── phase3-infra.yml    # 编排 k8s-infra
│   │   └── phase4-validate.yml # 编排 cluster-validate
│   └── ansible.cfg             # 禁用 host_key_checking, 指定 roles_path 等
└── README.md                   # 项目说明与快速启动指引
```



------

# 阶段1



------

# 阶段2



------

# 阶段3



------

# 阶段4





------

# 阶段5
