# -*- mode: ruby -*-
# vi: set ft=ruby :

# 定义全局变量，存放虚拟机IP地址
$ubuntu = "192.168.211.150"
$hadoop101 = "192.168.211.151"
$hadoop102 = "192.168.211.152"
$hadoop103 = "192.168.211.153"
$hadoop104 = "192.168.211.154"


Vagrant.configure("2") do |config|
  # ------------- 大数据集群节点-Hadoop1 -----------
  config.vm.define "hadoop1" do |hadoop1|
  # config.vm.define "hadoop1", autostart: false do |hadoop1|
    hadoop1.vm.box = "CentOS-7.9"
    hadoop1.vm.hostname = "hadoop1"
    # hadoop1.vm.network "private_network", type: "dhcp"
    # 下面这个地址是VMware虚拟网卡的 VMnet1（仅主机）的地址，没有选择NAT的那个网卡
    hadoop1.vm.network "private_network", ip: "#{$hadoop101}"
    hadoop1.vm.provider "vmware_desktop" do |vd|
      vd.gui = false
      vd.vmx["memsize"] = "3072"
      vd.vmx["numvcpus"] = "2"
    end
    hadoop1.vm.provision "shell", inline: "echo Hello From Vagrant CentOS-7.9-VM-hadoop1 Provision ..."
    # 使用下面的shell来配置Centos7里的yum源，默认以sudo权限执行
    hadoop1.vm.provision "shell", inline: "mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup"
    hadoop1.vm.provision "shell", inline: "curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo"
    hadoop1.vm.provision "shell", inline: "yum clean all && yum makecache"
    # 关闭SSH首次连接时的主机公钥验证
    hadoop1.vm.provision "NoStrictHostKeyChecking", type: "shell", inline: "echo '    StrictHostKeyChecking no' | tee -a /etc/ssh/ssh_config"
    # 添加集群节点的主机名配置
    hadoop1.vm.provision "config_hosts", type: "shell" do |s|
      s.inline = "echo -e '\n\n---------\n#{$hadoop101}  hadoop1\n#{$hadoop102}  hadoop2\n#{$hadoop103}  hadoop3' >> /etc/hosts"
    end
    # 手动编译安装一个Python3.8.12，因为Ubuntu-22.04安装的ansible-core是 2.17.8，它不支持Python2，并且要求最低Python3.7，而CentOS-7.9的yum源里只有 Python3.6
    # 安装编译所需的依赖
    hadoop1.vm.provision "install_python_dependencies", type: "shell", inline: "yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel gcc make"
    hadoop1.vm.provision "copy_python_source", type: "file", source: "大数据集群组件/Python-3.8.12.tgz", destination: "/home/vagrant/Python-3.8.12.tgz"
    hadoop1.vm.provision "untar_python", type: "shell", inline: "tar -zxf /home/vagrant/Python-3.8.12.tgz -C /home/vagrant"
    # 配置并进行编译+安装Python，启动时不会自动执行，需要手动执行
    hadoop1.vm.provision "configure_python", type: "shell", run: "never", inline: "cd /home/vagrant/Python-3.8.12 && ./configure"
    hadoop1.vm.provision "make_python", type: "shell", run: "never", inline: "cd /home/vagrant/Python-3.8.12 && make && make install"
  end

  # ------------- 大数据集群节点-Hadoop2 -----------
  config.vm.define "hadoop2" do |hadoop2|
  # config.vm.define "hadoop2", autostart: false do |hadoop2|
    hadoop2.vm.box = "CentOS-7.9"
    hadoop2.vm.hostname = "hadoop2"
    # hadoop2.vm.network "private_network", type: "dhcp"
    hadoop2.vm.network "private_network", ip: "#{$hadoop102}"
    hadoop2.vm.provider "vmware_desktop" do |vd|
      vd.gui = false
      vd.vmx["memsize"] = "3072"
      vd.vmx["numvcpus"] = "2"
    end
    hadoop2.vm.provision "shell", inline: "echo Hello From Vagrant CentOS-7.9-VM-hadoop2 Provision ..."
    hadoop2.vm.provision "shell", inline: "mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup"
    hadoop2.vm.provision "shell", inline: "curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo"
    hadoop2.vm.provision "shell", inline: "yum clean all && yum makecache"
    # 关闭SSH首次连接时的主机公钥验证
    hadoop2.vm.provision "NoStrictHostKeyChecking", type: "shell", inline: "echo '    StrictHostKeyChecking no' | tee -a /etc/ssh/ssh_config"
    # 添加集群节点的主机名配置
    hadoop2.vm.provision "config_hosts", type: "shell" do |s|
      s.inline = "echo -e '\n\n---------\n#{$hadoop101}  hadoop1\n#{$hadoop102}  hadoop2\n#{$hadoop103}  hadoop3' >> /etc/hosts"
    end
    # 安装Python3.8.12
    hadoop2.vm.provision "install_python_dependencies", type: "shell", inline: "yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel gcc make"
    hadoop2.vm.provision "copy_python_source", type: "file", source: "大数据集群组件/Python-3.8.12.tgz", destination: "/home/vagrant/Python-3.8.12.tgz"
    hadoop2.vm.provision "untar_python", type: "shell", inline: "tar -zxf /home/vagrant/Python-3.8.12.tgz -C /home/vagrant"
    # 配置并进行编译+安装Python，启动时不会自动执行，需要手动执行
    hadoop2.vm.provision "configure_python", type: "shell", run: "never", inline: "cd /home/vagrant/Python-3.8.12 && ./configure"
    hadoop2.vm.provision "make_python", type: "shell", run: "never", inline: "cd /home/vagrant/Python-3.8.12 && make && make install"
  end

  # ------------- 大数据集群节点-Hadoop3 -----------
  config.vm.define "hadoop3" do |hadoop3|
  # config.vm.define "hadoop3", autostart: false do |hadoop3|
    hadoop3.vm.box = "CentOS-7.9"
    hadoop3.vm.hostname = "hadoop3"
    # hadoop3.vm.network "private_network", type: "dhcp"
    hadoop3.vm.network "private_network", ip: "#{$hadoop103}"
    hadoop3.vm.provider "vmware_desktop" do |vd|
      vd.gui = false
      vd.vmx["memsize"] = "3072"
      vd.vmx["numvcpus"] = "2"
    end
    hadoop3.vm.provision "shell", inline: "echo Hello From Vagrant CentOS-7.9-VM-hadoop3 Provision ..."
    hadoop3.vm.provision "shell", inline: "mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup"
    hadoop3.vm.provision "shell", inline: "curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo"
    hadoop3.vm.provision "shell", inline: "yum clean all && yum makecache"
    # 关闭SSH首次连接时的主机公钥验证
    hadoop3.vm.provision "NoStrictHostKeyChecking", type: "shell", inline: "echo '    StrictHostKeyChecking no' | tee -a /etc/ssh/ssh_config"
    # 添加集群节点的主机名配置
    hadoop3.vm.provision "config_hosts", type: "shell" do |s|
      s.inline = "echo -e '\n\n---------\n#{$hadoop101}  hadoop1\n#{$hadoop102}  hadoop2\n#{$hadoop103}  hadoop3' >> /etc/hosts"
    end
    # 安装Python3.8.12
    hadoop3.vm.provision "install_python_dependencies", type: "shell", inline: "yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel gcc make"
    hadoop3.vm.provision "copy_python_source", type: "file", source: "大数据集群组件/Python-3.8.12.tgz", destination: "/home/vagrant/Python-3.8.12.tgz"
    hadoop3.vm.provision "untar_python", type: "shell", inline: "tar -zxf /home/vagrant/Python-3.8.12.tgz -C /home/vagrant"
    # 配置并进行编译+安装Python，启动时不会自动执行，需要手动执行
    hadoop3.vm.provision "configure_python", type: "shell", run: "never", inline: "cd /home/vagrant/Python-3.8.12 && ./configure"
    hadoop3.vm.provision "make_python", type: "shell", run: "never", inline: "cd /home/vagrant/Python-3.8.12 && make && make install"
  end

    # ------------- 大数据集群节点-Hadoop4 -----------
  # config.vm.define "hadoop4", autostart: false do |hadoop4|
  #     hadoop4.vm.box = "centos7"
  #     hadoop4.vm.hostname = "hadoop4"
  #     # hadoop4.vm.network "private_network", type: "dhcp"
  #     hadoop4.vm.network "private_network", ip: "#{$hadoop104}"
  #     hadoop4.vm.provider "vmware_desktop" do |vd|
  #       vd.gui = false
  #       vd.vmx["memsize"] = "1024"
  #       vd.vmx["numvcpus"] = "1"
  #     end
  #     hadoop4.vm.provision "shell", inline: "echo Hello From Vagrant CentOS-7.9-VM-hadoop4 Provision ..."
  #     hadoop4.vm.provision "shell", inline: "mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup"
  #     hadoop4.vm.provision "shell", inline: "curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo"
  #     hadoop4.vm.provision "shell", inline: "yum clean all && yum makecache"
  #     # 关闭SSH首次连接时的主机公钥验证
  #     hadoop4.vm.provision "NoStrictHostKeyChecking", type: "shell", inline: "echo '    StrictHostKeyChecking no' | tee -a /etc/ssh/ssh_config"
  #     # 安装Python3.8.12
  #     hadoop4.vm.provision "install_python_dependencies", type: "shell", inline: "yum -y install zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel libffi-devel gcc make"
  #     hadoop4.vm.provision "copy_python_source", type: "file", source: "大数据集群组件/Python-3.8.12.tgz", destination: "/home/vagrant/Python-3.8.12.tgz"
  #     hadoop4.vm.provision "untar_python", type: "shell", inline: "tar -zxf /home/vagrant/Python-3.8.12.tgz -C /home/vagrant"
  #     hadoop4.vm.provision "configure_python", type: "shell", inline: "cd /home/vagrant/Python-3.8.12 && ./configure"
  #     hadoop4.vm.provision "make_python", type: "shell", inline: "cd /home/vagrant/Python-3.8.12 && make && make install"
  #   end


  # ------------- Ansible控制节点-Ubuntu -----------
  # 这个节点的配置最好放在上面的集群节点配置后面，因为它里面要配置上面所有节点的ssh公钥连接
  config.vm.define "ubuntu" do |ubuntu|
    # config.vm.define "ubuntu", autostart: false do |ubuntu|
      ubuntu.vm.box = "Ubuntu-22.04"
      ubuntu.vm.hostname = "ubuntu-vm"
      # ubuntu.vm.network "private_network", type: "dhcp"
      ubuntu.vm.network "private_network", ip: "#{$ubuntu}"
      ubuntu.vm.provider "vmware_desktop" do |vd|
        vd.gui = false
        vd.vmx["memsize"] = "1024"
        vd.vmx["numvcpus"] = "1"
      end
      ubuntu.vm.provision "shell", inline: "echo Hello From Vagrant Ubuntu-22.04-VM Provision ..."
      # 使用下面的shell来配置Ubuntu-22.04里的apt源，默认以sudo权限执行
      # 备份源
      ubuntu.vm.provision "shell", inline: "mv /etc/apt/sources.list /etc/apt/sources.list.bak"
      # 配置阿里源
      ubuntu.vm.provision "shell", inline: "touch /etc/apt/sources.list"
      ubuntu.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy main multiverse restricted universe' >> /etc/apt/sources.list"
      ubuntu.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main multiverse restricted universe' >> /etc/apt/sources.list"
      ubuntu.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy-proposed main multiverse restricted universe' >> /etc/apt/sources.list"
      ubuntu.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy-security main multiverse restricted universe' >> /etc/apt/sources.list"
      ubuntu.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main multiverse restricted universe' >> /etc/apt/sources.list"
      # 配置ansible的PPA源
      ubuntu.vm.provision "shell", inline: "apt-get install software-properties-common"
      ubuntu.vm.provision "shell", inline: "apt-add-repository ppa:ansible/ansible"
      ubuntu.vm.provision "shell", inline: "apt-get update"
      # 安装ansible，Ubuntu-22.04 安装的ansible-core是 2.17.8，版本比较高，对应被控节点的Python版本要求也高，最低Python3.7，不支持Python2
      ubuntu.vm.provision "shell", inline: "apt-get install -y ansible"
      # 为 ansible.built.user 模块里的 password 参数安装一个Python依赖包
      ubuntu.vm.provision "shell", inline: "apt-get install -y python3-passlib"
  
      # 关闭SSH首次连接时的主机公钥验证
      ubuntu.vm.provision "NoStrictHostKeyChecking", type: "shell", inline: "echo '    StrictHostKeyChecking no' | tee -a /etc/ssh/ssh_config"
      # 添加集群节点的主机名配置
      ubuntu.vm.provision "config_hosts", type: "shell" do |s|
        s.inline = "echo -e '\n\n---------\n#{$hadoop101}  hadoop1\n#{$hadoop102}  hadoop2\n#{$hadoop103}  hadoop3' >> /etc/hosts"
      end

      # 从环境变量 ANSIBLE_TAGS 和 ANSIBLE_SKIP_TAGS 中获取要执行或者跳过的tags
      ansible_opts = {}
      if ENV['ANSIBLE_TAGS']
        ansible_opts[:tags] = ENV['ANSIBLE_TAGS'].split(",")
      else
        ansible_opts[:tags] = []  # 默认的 tags
      end
      ansible_opts[:skip_tags] = ENV['ANSIBLE_SKIP_TAGS'] ? ENV['ANSIBLE_SKIP_TAGS'].split(",") : []

      # ---- ansible部署大数据组件 ----
      ubuntu.vm.provision "deploy_cluster", type: "ansible_local", run: "never" do |ansible|
        ansible.install = false
        # ansible.install_mode = ":default"
        ansible.compatibility_mode = "2.0"
        # 设置ansible日志级别
        # ansible.verbose = "-vvv"
        # ---- 指定待执行的 playbook ----
        ansible.playbook = "provision-ansible/main-playbook.yml"

        # 打印可配置的环境变量当前值
        puts "ANSIBLE_LIST_HOSTS: #{ENV['ANSIBLE_LIST_HOSTS']}"
        puts "ANSIBLE_LIST_TAGS:  #{ENV['ANSIBLE_LIST_TAGS']}"
        puts "ANSIBLE_LIST_TASKS: #{ENV['ANSIBLE_LIST_TASKS']}"
        puts "ANSIBLE_TAGS:       #{ENV['ANSIBLE_TAGS']}"
        puts "ANSIBLE_SKIP_TAGS:  #{ENV['ANSIBLE_SKIP_TAGS']}"

        # ---- ansible check模式，不实际执行 ----
        # ansible.raw_arguments = "--list-hosts" # 检查待执行的主机名单
        # ansible.raw_arguments = "--list-tags"  # 检查待执行的tags
        # ansible.raw_arguments = "--list-tasks" # 检查待执行的tasks
        # 这里改为使用环境变量控制
        if ENV['ANSIBLE_LIST_HOSTS'] == 'true'
          ansible.extra_vars = { ansible_check_mode: true }
          ansible.raw_arguments = ['--list-hosts']
        elsif ENV['ANSIBLE_LIST_TAGS'] == 'true'
          ansible.extra_vars = { ansible_check_mode: true }
          ansible.raw_arguments = ['--list-tags']
        elsif ENV['ANSIBLE_LIST_TASKS'] == 'true'
          ansible.extra_vars = { ansible_check_mode: true }
          ansible.raw_arguments = ['--list-tasks']
        end
        
        # ---- 指定执行的任务tags ----
        # 指定playbook中哪些tags可以执行
        # main-playbool.yml
        # ansible.tags = ["config_nodes", "java", "mysql_redis", "cluster"]
        # config-nodes-playbook.yml
        # ansible.tags = ["ubuntu_ssh_key", "swap_off", "hosts", "hadoop_user", "hadoop_sshkey"]
        # deploy-java-playbook.yml + deploy-mysql-redis-playbook.yml
        # ansible.tags = ["java", "mysql", "redis"]
        # deploy-cluster-playbook.yml
        # ansible.tags = ["hadoop", "zookeeper", "kafka", "hive", "spark", "flink", "hbase"]
        ansible.tags = ansible_opts[:tags]
        # 指定playbook中哪些tags跳过执行
        # ansible.skip_tags = []
        ansible.skip_tags = ansible_opts[:skip_tags]

        # ---- 指定主机清单 ----
        # 下面的 limit 一定要设置为 all，因为默认限制只有当前VM可以作为目标主机执行playbook，会导致上面设置的主机分组无法被playbook里的play识别
        ansible.limit = "all"
        # 可以进入虚拟机里通过 cat /tmp/vagrant-ansible/inventory/vagrant_ansible_local_inventory 查看生成的主机清单
        ansible.host_vars = {
          "hadoop1" => {
            "ansible_host" => "#{$hadoop101}", "ansible_connection" => "ssh", "ansible_ssh_user" => "vagrant", "ansible_ssh_pass" => "vagrant",
            "ansible_ssh_common_args" => "'-o StrictHostKeyChecking=no'", "ansible_python_interpreter" => "/usr/local/bin/python3.8"
          },
          "hadoop2" => {
            "ansible_host" => "#{$hadoop102}", "ansible_connection" => "ssh", "ansible_ssh_user" => "vagrant", "ansible_ssh_pass" => "vagrant", 
            "ansible_ssh_common_args" => "'-o StrictHostKeyChecking=no'", "ansible_python_interpreter" => "/usr/local/bin/python3.8"
          },
          "hadoop3" => {
            "ansible_host" => "#{$hadoop103}", "ansible_connection" => "ssh", "ansible_ssh_user" => "vagrant", "ansible_ssh_pass" => "vagrant", 
            "ansible_ssh_common_args" => "'-o StrictHostKeyChecking=no'", "ansible_python_interpreter" => "/usr/local/bin/python3.8"
          },
          # "hadoop4" => {
          #   "ansible_host" => "#{$hadoop104}", "ansible_connection" => "ssh", "ansible_ssh_user" => "vagrant", "ansible_ssh_pass" => "vagrant", 
          #   "ansible_ssh_common_args" => "'-o StrictHostKeyChecking=no'", "ansible_python_interpreter" => "/usr/local/bin/python3.8"
          # }
        }
        ansible.groups = {
          "mysql_node" => ["hadoop1"],
          "redis_node" => ["hadoop2"],
          # "hadoop_nodes" => ["hadoop1"],
          "hadoop_nodes" => ["hadoop1", "hadoop2", "hadoop3"],
          "hive_node" => ["hadoop3"],
          "spark_node" => ["hadoop3"],
          "flink_node" => ["hadoop3"]
          # ,"hadoop_nodes:vars" => {"ansible_connection" => "ssh", "ansible_ssh_user" => "vagrant", "ansible_ssh_pass" => "vagrant"}
        }
      end
    end
end