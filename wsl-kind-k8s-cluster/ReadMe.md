# 目录

[TOC]


# 介绍

基于 WSL2 + Kind + Ansible 搭建云原生大数据平台。


## 阶段 0：WSL2 硬件资源配置

> **目标**：在 Windows 宿主机层面划定 WSL2 虚拟机的资源上限，防止大数据组件触发 OOM Kill 导致集群丢失。此阶段必须在 Ansible 介入前完成。

| 主要任务          | 说明                                                       | 交付物/验证标准                           |
| :---------------- | :--------------------------------------------------------- | :---------------------------------------- |
| 编辑 `.wslconfig` | 参考 `scripts/wslconfig.ini` 配置 `memory`, `processors`, `swap`, `localhostForwarding` | 文件存在于 `%UserProfile%\.wslconfig`     |
| 重启 WSL2 实例    | 执行 `wsl --shutdown` 使硬件资源配置生效                       | `wsl -l -v` 显示 Running 且资源限制已应用 |
| 进入 WSL2 验证    | 确认分发版正常启动，资源符合预期                           | `free -h`, `nproc` 输出与配置一致         |

## 阶段 1：Bootstrap 与 OS/容器运行时初始化

> **目标**：完成 Ansible 自举，并将 WSL2 从"裸发行版"转变为"生产就绪的容器宿主"。本阶段分为手动引导和 Ansible 接管两部分。

| 主要任务           | 执行方式              | 说明                                               | 交付物/验证标准                            |
| :----------------- | :-------------------- | :------------------------------------------------- | :----------------------------------------- |
| 安装前置依赖       | 🖐️ 手动 / `scripts/bootstrap.sh` | 运行 `sudo scripts/bootstrap.sh` 安装 `python3-pip`, `ansible`, `docker-ce`         | Ansible CLI 可用，Docker 二进制存在        |
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
## 项目结构

```
wsl-kind-k8s-cluster/
├── scripts/                    # 脚本和配置文件目录
│   ├── wslconfig.ini           # Phase 0: WSL2硬件配置模板
│   ├── bootstrap.sh            # Phase 1: 手动引导脚本（装 Ansible + Docker CE）
│   ├── download-k8s-cli.sh     # K8s CLI工具离线下载脚本(Bash)
│   ├── download-k8s-cli.ps1    # K8s CLI工具离线下载脚本(PowerShell)
│   └── validate-phase2.sh      # Phase 2集群验证脚本
├── ansible/
│   ├── inventory/
│   │   └── local.ini           # 仅含 localhost ansible_connection=local
│   ├── group_vars/
│   │   └── all.yml             # 全局变量：版本号、端口、路径等
│   ├── roles/
│   │   ├── wsl2-tuning/        # Phase 1: sysctl, limits, 用户组, 目录
│   │   ├── docker-engine/      # Phase 1: daemon.json, service state
│   │   ├── k8s-cli-tools/      # Phase 2: CLI工具安装
│   │   ├── kind-cluster/       # Phase 2: kind-config, 集群创建, kubeconfig同步
│   │   ├── k8s-infra/          # Phase 3: Registry, MetalLB, Ingress, Metrics, LocalPV
│   │   └── cluster-validate/   # Phase 4: 冒烟测试, 访问信息输出
│   ├── playbooks/
│   │   ├── phase1-init.yml     # 编排 wsl2-tuning + docker-engine
│   │   ├── phase2-kind.yml     # 编排 kind-cluster
│   │   ├── phase3-infra.yml    # 编排 k8s-infra
│   │   └── phase4-validate.yml # 编排 cluster-validate
│   └── ansible.cfg             # 禁用 host_key_checking, 指定 roles_path 等
└── ReadMe.md                   # 项目说明与快速启动指引
```



------

# 阶段1



------

# 阶段2

## 执行说明

### 前置条件
- ✅ 已完成阶段0：WSL2硬件资源配置（`.wslconfig`已生效）
- ✅ 已完成阶段1：系统初始化和Docker Engine安装

### 执行命令

在 WSL2 终端中执行：

```bash
cd /path/to/wsl-kind-k8s-cluster/ansible

# 执行阶段2 Playbook
ansible-playbook playbooks/phase2-kind.yml

# 或者使用标签选择性执行
ansible-playbook playbooks/phase2-kind.yml --tags cli      # 仅安装CLI工具
ansible-playbook playbooks/phase2-kind.yml --tags kind     # 仅创建Kind集群
```

### 验证步骤

1. **检查CLI工具版本**
   ```bash
   kubectl version --client --short
   kind version
   helm version --short
   ```

2. **检查Kind集群状态**
   ```bash
   kind get clusters
   kubectl get nodes -o wide
   ```

3. **Windows侧验证**
   在Windows PowerShell中执行：
   ```powershell
   kubectl get nodes
   ```

4. **自动化验证脚本**
   ```bash
   chmod +x scripts/validate-phase2.sh
   scripts/validate-phase2.sh
   ```

### 预期输出

执行成功后，你应该看到类似以下输出：

```
═══════════════════════════════════════════════════════
  🎉 Phase 2 完成 - Kind 集群就绪
═══════════════════════════════════════════════════════

📊 集群节点状态:
NAME                      STATUS   ROLES           AGE   VERSION
bigdata-lab-control-plane Ready    control-plane   5m    v1.31.14
bigdata-lab-worker        Ready    <none>          4m    v1.31.14
bigdata-lab-worker2       Ready    <none>          4m    v1.31.14

📦 系统组件状态:
NAMESPACE            NAME                                        READY   STATUS
kube-system          coredns-xxxxx                               1/1     Running
kube-system          etcd-bigdata-lab-control-plane              1/1     Running
kube-system          kube-apiserver-...                          1/1     Running
kube-system          kube-controller-manager-...                 1/1     Running
kube-system          kube-proxy-xxxxx                            1/1     Running
kube-system          kube-scheduler-...                          1/1     Running

🔗 访问信息:
   WSL2 kubeconfig: /home/<user>/.kube/config
   Windows kubeconfig: /mnt/c/Users/<user>/.kube/config

📝 下一步操作:
   1. 在 WSL2 中执行: kubectl get nodes
   2. 在 Windows PowerShell 中执行: kubectl get nodes
   3. 继续执行 Phase 3 部署基础设施组件

═══════════════════════════════════════════════════════
```

---
## 技术细节

### CLI工具安装策略
- **双模式支持**：支持网络下载和本地文件两种安装方式，通过`k8s_cluster_local.from_local`切换
- **幂等性保证**：先检测已安装版本，仅在版本不匹配或未安装时才安装
- **版本校验**：网络下载时使用SHA256 checksum验证kubectl二进制完整性
- **架构自适应**：自动检测x86_64或arm64架构并下载对应版本
- **超时控制**：网络下载设置300秒超时，避免长时间等待

### 本地文件安装配置（应对网络问题）

当网络下载缓慢或不稳定时，可以切换到本地文件安装模式：

**1. 准备本地文件**

**方法A：使用自动化下载脚本（推荐）**

在项目根目录的 `scripts/` 目录下提供了两个下载脚本：

```bash
# 在WSL2中使用bash脚本
chmod +x scripts/download-k8s-cli.sh
./scripts/download-k8s-cli.sh ~/k8s-cli-offline

# 或在Windows PowerShell中使用
.\scripts\download-k8s-cli.ps1 C:\k8s-cli-offline
```

脚本会自动下载正确版本的kubectl、kind和helm文件。

**方法B：手动下载**

在Windows侧下载好以下文件（注意必须是Linux amd64版本）：
```powershell
# kubectl (直接下载二进制文件)
curl -LO "https://dl.k8s.io/release/v1.31.1/bin/linux/amd64/kubectl"

# kind (直接下载二进制文件)
curl -LO "https://kind.sigs.k8s.io/dl/v0.24.0/kind-linux-amd64"
mv kind-linux-amd64 kind

# helm (下载压缩包)
curl -LO "https://get.helm.sh/helm-v3.16.2-linux-amd64.tar.gz"
```

**2. 配置本地路径**

编辑 `ansible/group_vars/all.yml`，修改以下配置：

```yaml
k8s_cluster_local:
  from_local: true  # 启用本地安装模式
  kubectl: "/mnt/c/Users/YourName/Downloads/kubectl"
  kind: "/mnt/c/Users/YourName/Downloads/kind"
  helm: "/mnt/c/Users/YourName/Downloads/helm-v3.16.2-linux-amd64.tar.gz"
```

**注意事项：**
- 路径必须是WSL2可访问的绝对路径（通常通过`/mnt/c/`访问Windows文件系统）
- `kubectl`和`kind`必须是Linux amd64架构的二进制文件，不是Windows exe
- `helm`必须是`.tar.gz`格式的Linux压缩包
- 确保文件具有可读权限

**3. 执行安装**

```bash
cd wsl-kind-k8s-cluster/ansible
ansible-playbook playbooks/phase2-kind.yml --tags cli
```

执行时会显示详细的安装信息：
```
═══════════════════════════════════════════════════
  📦 K8s CLI 工具安装配置
═══════════════════════════════════════════════════
  安装模式: 📁 本地文件

  🔧 kubectl v1.31.1
     来源: /mnt/c/Users/YourName/Downloads/kubectl

  🔧 kind v0.24.0
     来源: /mnt/c/Users/YourName/Downloads/kind

  🔧 helm v3.16.2
     来源: /mnt/c/Users/YourName/Downloads/helm-v3.16.2-linux-amd64.tar.gz

═══════════════════════════════════════════════════
```

### Kind集群配置要点
- **节点拓扑**：1个control-plane + 2个worker节点
- **数据持久化**：通过extraMounts将WSL2路径映射到容器内
- **端口映射**：
  - 80 → 30080 (Ingress HTTP)
  - 443 → 30443 (Ingress HTTPS)
  - 30000+ (NodePort范围)
- **CNI禁用**：disableDefaultCNI=true，为Phase 3部署Calico/Cilium预留

### kubeconfig同步机制
- **WSL2侧**：导出到 `~/.kube/config`
- **Windows侧**：自动复制到 `/mnt/c/Users/$USER/.kube/config`
- **地址修正**：将API Server地址从127.0.0.1改为localhost以确保Windows可访问


### 关键变量说明

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `k8s_versions.kind` | v0.24.0 | Kind版本 |
| `k8s_versions.kubectl` | v1.31.1 | kubectl版本 |
| `k8s_versions.helm` | v3.16.2 | Helm版本 |
| `kind_cluster.name` | bigdata-lab | 集群名称 |
| `kind_cluster.node_image` | kindest/node:v1.31.14 | 节点镜像（需与kubectl版本匹配） |
| `kind_cluster.pod_subnet` | 10.244.0.0/16 | Pod CIDR |
| `kind_cluster.service_subnet` | 10.96.0.0/12 | Service CIDR |
| `kind_cluster.data_mount_host` | /opt/k8s-data | WSL2侧数据目录 |
| `kind_cluster.data_mount_container` | /data | 容器内挂载点 |


---
## 故障排查

### 问题1：Kind集群创建失败
```bash
# 查看Kind日志
kind export logs ./kind-logs

# 删除失败集群后重试
kind delete cluster --name bigdata-lab
ansible-playbook playbooks/phase2-kind.yml --tags kind
```

### 问题2：kubeconfig同步到Windows失败
手动复制配置文件：
```bash
# 在WSL2中执行
cp ~/.kube/config /mnt/c/Users/$USER/.kube/config

# 或在Windows PowerShell中执行
wsl kind export kubeconfig --name bigdata-lab
```

### 问题3：节点长时间NotReady
```bash
# 检查CNI插件状态
kubectl get pods -n kube-system

# 查看节点详细状态
kubectl describe node <node-name>

# 检查容器运行时
docker ps | grep kind
```

### 问题4：Helm安装失败
```bash
# 清理临时文件
rm -rf /tmp/helm-* /tmp/linux-*

# 重新执行
ansible-playbook playbooks/phase2-kind.yml --tags cli
```
