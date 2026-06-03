# CloudNative 项目 - AI Coding Agent 指南

> 云原生与大数据基础设施研究项目，包含两个独立的子项目。

---

## 项目结构

```
CloudNative/
├── vagrant-cluster/          # Vagrant + Ansible 大数据集群 (Hadoop/Spark/Kafka/MySQL/Redis...)
└── wsl-kind-k8s-cluster/     # WSL2 + Kind + Ansible 本地 K8s 平台
```

---

## 子项目 1：vagrant-cluster（大数据集群）

基于 Vagrant (VMware Desktop) + Ansible 在本地部署多节点大数据集群。

- **VM 节点**：1 个 Ubuntu 控制节点 + 3 个 CentOS 7.9 Hadoop 节点
- **技术栈**：Java, MySQL 8.0, Redis, Hadoop, Zookeeper, Kafka, Hive, Spark, Flink, HBase
- **文档**：[Vagrant-Commands.md](vagrant-cluster/Vagrant-Commands.md)

### 运行命令

```bash
# 切换 Vagrantfile
$env:VAGRANT_VAGRANTFILE="Vagrantfile-Cluster.rb"   # PowerShell
export VAGRANT_VAGRANTFILE=Vagrantfile-Cluster.rb    # Bash

# 基本操作
vagrant up
vagrant status
vagrant halt
vagrant destroy
```

### Ansible 角色约定

- 自定义角色命名：`zxt.<组件名>`（如 `zxt.hadoop`, `zxt.mysql`）
- 社区角色：`geerlingguy.*`（redis, swap）
- 主入口：[provision-ansible/main-playbook.yml](vagrant-cluster/provision-ansible/main-playbook.yml)

### 已知问题

- CentOS 7.9 自带 Python 3.6，Ansible Core 2.17+ 需要 Python 3.7+ → 需手动编译 Python 3.8.12
- MySQL 8.x 在 CentOS 7 上安装需要 `zxt.mysql` 自定义角色，社区角色不适用
- 依赖本地 tar 包位于 `/vagrant/大数据集群组件/`


---

## 子项目 2：wsl-kind-k8s-cluster（K8s 本地平台）

基于 WSL2 + Kind + Ansible 在本地搭建多节点 Kubernetes 集群，逐步部署完整的大数据技术栈。

- **7 个阶段**：WSL 调优 → Docker/Ansible 自举 → Kind 集群创建 → 基础设施 → 存储消息 → 计算引擎 → 可观测性
- **工具链**：kind v0.24.0, kubectl v1.31.1, helm v3.16.2
- **文档**：[Kind-K8S.md](wsl-kind-k8s-cluster/Kind-K8S.md)

### 运行命令

```bash
# 阶段 0：Windows 侧配置 .wslconfig，然后 wsl --shutdown 重启生效。

# 阶段 1：WSL2 内 bootstrap
sudo ./scripts/bootstrap.sh

# 阶段 2-7：Ansible 接管（在 ansible/ 目录下执行）
ansible-playbook playbooks/phase1-init.yml
ansible-playbook playbooks/phase2-kind.yml
ansible-playbook playbooks/phase3-infra.yml
ansible-playbook playbooks/phase4-validate.yml
ansible-playbook playbooks/phase5-storage-msg.yml      # MinIO + Strimzi Kafka
ansible-playbook playbooks/phase6-compute.yml          # Spark/Flink Operator + Volcano
ansible-playbook playbooks/phase7-observability.yml    # Prometheus/Grafana 监控
```

### 关键约定

- Ansible 配置：[ansible.cfg](wsl-kind-k8s-cluster/ansible/ansible.cfg) — `transport=local`, 本地执行
- 所有变量集中管理：[group_vars/all.yml](wsl-kind-k8s-cluster/ansible/group_vars/all.yml)
- 版本严格锁定，禁止随意升级 K8s 生态组件版本
- Playbook 按阶段拆分，角色按功能命名（`wsl2-tuning`, `docker-engine`, `k8s-cli-tools`, `kind-cluster`, `k8s-infra`, `minio-operator`, `strimzi-kafka`, `spark-operator`, `flink-operator`, `volcano-scheduler`, `observability`）

### 工程约束（来自 Kind-K8S.md）

- **Operator 优先**：阶段 5-6 所有中间件与计算引擎必须通过 Operator 部署，禁止裸 Helm Chart 或 StatefulSet
- **存储依赖链**：阶段 5 MinIO 依赖阶段 3 Local PV Provisioner；阶段 6 Flink Checkpoint 依赖阶段 5 MinIO — 严格执行阶段顺序
- **调度器共存**：Volcano 作为补充调度器，系统组件仍由 default-scheduler 调度，仅大数据作业通过 `schedulerName: volcano` 指定
- **可观测性后置**：阶段 7 放在最后以避免提前部署导致大量 Target Down 告警
- **资源预算**：阶段 5-7 额外消耗 4-6GB 内存，`.wslconfig` 建议 ≥24GB

---

## 通用约定

- **语言**：文档和注释使用中文，配置/代码标识符使用英文
- **Ansible 模式**：两个子项目都使用 Ansible 作为配置管理工具，但独立运行、互不依赖
- **版本锁定**：所有关键组件版本严格锁定，避免版本漂移
- **幂等性**：所有 Ansible playbook 和角色必须保持幂等
