# CloudNative 项目 - AI Coding Agent 指南

> 云原生与大数据基础设施研究项目，包含三个独立的子项目。

---

## 项目结构

```
CloudNative/
├── vagrant-cluster/          # Vagrant + Ansible 大数据集群 (Hadoop/Spark/Kafka/MySQL/Redis...)
├── wsl-kind-k8s-cluster/     # WSL2 + Kind + Ansible 本地 K8s 平台
└── go-cloud/                 # Go 语言学习与云原生应用开发
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

## 子项目 3：go-cloud（Go 语言学习与云原生开发）

基于 Go 语言，从基础语法到云原生应用开发的系统性学习项目。

- **学习路线**：基础语法 → 高级特性 → 并发编程 → Web 开发 → 云原生应用
- **Go 版本**：1.22+
- **文档**：[Go-Learning.md](go-cloud/Go-Learning.md)

### 运行命令

```bash
# 学习沙盒示例
go run ./examples/01-basics          # 基础语法
go run ./examples/02-concurrency     # 并发模式
go run ./examples/03-advanced        # 高级特性

# 或使用 Makefile
make example-basics
make example-concurrency
make example-advanced
make examples                        # 运行所有示例

# Web 服务
make run-server                      # 启动 Web 服务 (localhost:8080)
go run ./cmd/server

# CLI 工具
make run-cli ARGS="hello"
go run ./cmd/cli hello

# 构建与测试
make build                           # 编译二进制到 bin/
make test                            # 运行所有测试
make test-cover                      # 测试覆盖率报告
make lint                            # 代码静态检查
```

### 关键约定

- **Go Module**：`go-cloud/` 有独立的 `go.mod`（module `github.com/zxt/go-cloud`），与项目根目录互不干扰
- **分层架构**：`internal/` 下按 handler → service → repository → model 分层，遵循依赖倒置原则
- **学习沙盒**：`examples/` 目录下的代码是独立的 `package main`，可直接 `go run`，不依赖项目其他包
- **私有隔离**：`internal/` 下的包不可被外部模块导入，Go 编译器强制保证
- **公共库**：`pkg/` 下的包可被其他项目导入，需保持 API 稳定性
- **配置管理**：配置文件放在 `configs/`，加载代码放在 `pkg/config/`
- **测试约定**：单元测试与源码同目录（`*_test.go`），集成测试放在 `test/integration/`

### 工程约束

- **Go 版本锁定**：`go.mod` 中 `go` 指令锁定最低版本，禁止随意升级
- **无 CGO 优先**：云原生部署场景优先使用 `CGO_ENABLED=0` 构建静态二进制
- **错误处理**：统一使用 `pkg/errcode` 错误码体系，禁止裸返回 `errors.New()`
- **并发安全**：所有共享状态必须通过 `sync` 包或 channel 保护，`go test -race` 必须通过

---

## 通用约定

- **语言**：文档和注释使用中文，配置/代码标识符使用英文
- **Ansible 模式**：vagrant-cluster 和 wsl-kind-k8s-cluster 使用 Ansible 作为配置管理工具，但独立运行、互不依赖；go-cloud 不使用 Ansible
- **版本锁定**：所有关键组件版本严格锁定，避免版本漂移
- **幂等性**：所有 Ansible playbook 和角色必须保持幂等
