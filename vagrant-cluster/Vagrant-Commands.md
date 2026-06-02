
# Vagrant Box 安装

```shell
vagrant box add --name CentOS-7.9 /Users/danielzhang/Downloads/Softwares/bento_centos-7_202401.31.0_parallels.box
vagrant box add --name Ubuntu-20.04 /Users/danielzhang/Downloads/Softwares/bent_ubuntu-20.04_202404.23.0_parallels.box
vagrant box add --name Ubuntu-22.04 /Users/danielzhang/Downloads/Softwares/bent_ubuntu-22.04_202401.31.0_parallels_amd64.box
```

# 工作路径及环境变量设置

```shell
cd 'D:\Vagrant\vagrant-cluster'

# powershell
$env:VAGRANT_VAGRANTFILE="Vagrantfile-CentOS.rb"
$env:VAGRANT_VAGRANTFILE="Vagrantfile-Ubuntu.rb"
$env:VAGRANT_VAGRANTFILE="Vagrantfile-Cluster.rb"

# shell
export VAGRANT_VAGRANTFILE=Vagrantfile-CentOS.rb
export VAGRANT_VAGRANTFILE=Vagrantfile-Ubuntu.rb
export VAGRANT_VAGRANTFILE=Vagrantfile-Cluster.rb
```


# 调试Ansible

```shell
vagrant up
vagrant status
vagrant halt
vagrant destroy

vagrant scp ./provision-ansible/main-playbook ubuntu:/vagrant/provision-ansible

# ------ 初始配置 ------
vagrant provision hadoop1
vagrant provision hadoop1 --provision-with NoStrictHostKeyChecking
vagrant provision hadoop1 --provision-with untar_python
vagrant provision ubuntu --provision-with NoStrictHostKeyChecking
vagrant provision ubuntu --provision-with config_hosts

# ------ Hadoop[1-3] 编译安装Python ------
# vagrant provision hadoop1 --provision-with configure_python
# vagrant provision hadoop1 --provision-with make_python
# vagrant provision hadoop1 --provision-with configure_python,make_python
vagrant provision /hadoop[1-3]/ --provision-with configure_python
vagrant provision /hadoop[1-3]/ --provision-with make_python
vagrant provision /hadoop[1-3]/ --provision-with configure_python,make_python

# ------ Hadoop[1-3] 快照保存 ------
vagrant snapshot list
# vagrant snapshot push
# vagrant snapshot pop
vagrant snapshot save hadoop1 hadoop1-python
vagrant snapshot save hadoop2 hadoop2-python
vagrant snapshot save hadoop3 hadoop3-python
vagrant snapshot restore hadoop1 hadoop1-python
vagrant snapshot restore hadoop2 hadoop2-python
vagrant snapshot restore hadoop3 hadoop3-python

# ------ Ubuntu节点执行 Ansible-Playbook 配置 Hadoop[1-3] ------
# 使用环境变量来检查 ansible-playbook 的执行细节
$env:ANSIBLE_LIST_HOSTS="true"
$env:ANSIBLE_LIST_TAGS="true"
$env:ANSIBLE_LIST_TASKS="true"
$env:ANSIBLE_LIST_HOSTS="false"
$env:ANSIBLE_LIST_TAGS="false"
$env:ANSIBLE_LIST_TASKS="false"
# 修改 Vagrantfile-Cluster里的 ansible.tags 来控制执行哪些任务
# 也可以配置环境变量来设置
$env:ANSIBLE_TAGS="config_nodes,java,mysql_redis,cluster"
$env:ANSIBLE_TAGS="java,mysql,redis"
$env:ANSIBLE_TAGS="hadoop,zookeeper,kafka,hive,spark,flink,hbase"

$env:ANSIBLE_TAGS="config_nodes"
$env:ANSIBLE_TAGS="java"
$env:ANSIBLE_TAGS="mysql"
$env:ANSIBLE_TAGS="redis"
$env:ANSIBLE_TAGS="hadoop"
$env:ANSIBLE_TAGS="zookeeper"
$env:ANSIBLE_TAGS="kafka"
$env:ANSIBLE_TAGS="hive"
$env:ANSIBLE_TAGS="spark"
$env:ANSIBLE_TAGS="flink"
$env:ANSIBLE_TAGS="hbase"
vagrant provision ubuntu --provision-with deploy_cluster

```

# 命令行调试Ansible
- 主机清单文件
```ini
; 文件名为：command-inventory.ini
[hadoop]
hadoop1
```

- 检查 ansible 在 CentOS-7 下识别的包管理器是否正确
```shell
# 直接指定主机名不行
# ansible -i "hadoop1" -m setup -a "filter=ansible_pkg_mgr"

ansible hadoop -i ./command-inventory.ini -m setup -a "filter=ansible_pkg_mgr"

ansible hadoop -i ./command-inventory.ini -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no' ansible_ssh_pass=vagrant ansible_python_interpreter=/usr/local/bin/python3.8" -m setup -a "filter=ansible_pkg_mgr"

```

ansible: error: the following arguments are required: pattern

ansible -i hadoop1, --ssh-common-args '-i ~/.ssh/id_ssh_rsa_hadoop' -u vagrant -m setup hadoop1

# 命令记录

-i https://pypi.tuna.tsinghua.edu.cn/simple

1. 关闭selinux
2. 关闭swap
3. 配置SSH免密登录
4. 安装MySQL
    4.1 在MySQL官网下载centos-7的 rpm.bundle.tar 包
    

wget http://dev.mysql.com/get/mysql84-community-release-el7-1.noarch.rpm
rpm -ivh mysql84-community-release-el7-1.noarch.rpm

rpm -ivh /vagrant/大数据集群组件/mysql84-community-release-el7-1.noarch.rpm

rpm -qa | grep mariadb
sudo yum remove mariadb*
rm -rf /etc/my.cnf
rm -rf /var/lib/mysql/

sudo yum list installed | grep mysql

sudo yum remove mysql-community*

sudo yum list installed | grep mysql-community | awk '{print $1}' | xargs -r sudo yum remove -y

sudo yum install mysql-community-client.x86_64 mysql-community-common.x86_64 mysql-community-devel.x86_64 mysql-community-libs.x86_64 mysql-community-server.x86_64

sudo rm -rf /etc/my.cnf*   &&
sudo rm -rf /var/lib/mysql*  &&
sudo rm -rf /var/log/mysql*  &&
sudo rm -rf /var/run/mysql*

sudo systemctl status mysqld
sudo systemctl start mysqld
sudo systemctl stop mysqld

sudo cp /etc/my.cnf /etc/my.cnf.origin

sudo cat /etc/my.cnf
sudo ls -al /etc | grep my
sudo ls -al /var/log | grep mysql
sudo ls -al /var/lib | grep mysql
sudo ls -al /var/run | grep mysql
sudo ls -al /run | grep mysql

sudo vi /var/log/mysqld.log
sudo journalctl -u mysqld -e

SHOW VARIABLES LIKE 'validate_password%';
SHOW PLUGINS;

yum install mysql-community-client.x86_64 mysql-community-common.x86_64 mysql-community-devel.x86_64 mysql-community-libs.x86_64 mysql-community-server.x86_64

yum install mysql-community-libs-compat.x86_64

pip3 install -i https://pypi.tuna.tsinghua.edu.cn/simple pymysql cryptography


sudo rm -rf /opt/hadoop/hadoop-3.2.4/data/namenode/*
sudo rm -rf /opt/hadoop/hadoop-3.2.4/data/datanode/*
sudo rm -rf /opt/hadoop/hadoop-3.2.4/data/nodemanager/*
sudo rm -rf /opt/hadoop/hadoop-3.2.4/logs/*
sudo rm -rf /tmp/hadoop*

su - hdfs -c "/opt/hadoop/current/bin/hdfs namenode -format my-cluster"

su - hdfs -c "/opt/hadoop/current/bin/hdfs --daemon start namenode &"
su - hdfs -c "/opt/hadoop/current/bin/hdfs --daemon start datanode &"

su - hdfs -c "/opt/hadoop/current/bin/hdfs --daemon stop namenode"
su - hdfs -c "/opt/hadoop/current/bin/hdfs --daemon stop datanode"

su - yarn -c "/opt/hadoop/current/bin/yarn --daemon start resourcemanager &"
su - yarn -c "/opt/hadoop/current/bin/yarn --daemon start nodemanager &"

su - yarn -c "/opt/hadoop/current/bin/yarn --daemon stop resourcemanager"
su - yarn -c "/opt/hadoop/current/bin/yarn --daemon stop nodemanager"


su - hdfs -c "/opt/hadoop/current/sbin/start-dfs.sh"
su - hdfs -c "/opt/hadoop/current/sbin/stop-dfs.sh"

su - yarn -c "/opt/hadoop/current/sbin/start-yarn.sh"
su - yarn -c "/opt/hadoop/current/sbin/stop-yarn.sh"


su - hadoop -c "/opt/zookeeper-3.5.9/bin/zkServer.sh start"
su - hadoop -c "/opt/zookeeper-3.5.9/bin/zkServer.sh stop"
su - hadoop -c "/opt/zookeeper-3.5.9/bin/zkServer.sh status"

su - hadoop -c "/opt/kafka-3.1.2/bin/kafka-server-start.sh -daemon /opt/kafka-3.1.2/config/server.properties"
su - hadoop -c "/opt/kafka-3.1.2/bin/kafka-server-start.sh -daemon /opt/kafka-3.1.2/config/server.properties --override kafka.logs.dir=/opt/kafka-3.1.2/logs"
su - hadoop -c "/opt/kafka-3.1.2/bin/kafka-server-stop.sh -daemon /opt/kafka-3.1.2/config/server.properties"