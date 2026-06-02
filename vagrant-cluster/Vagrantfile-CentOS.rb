# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "CentOS-7.9"
  # 设置虚拟机的名称
  config.vm.define "centos-7.9-vm"
  # 设置主机名
  config.vm.hostname = "centos-zxt"
  # 设置启动后显示的信息
  config.vm.post_up_message = "Hello CentOS-7.9 From Vagrant"

  # config.vm.network "public_network"
  # config.vm.network "private_network", type: "dhcp"
  config.vm.network "private_network", ip: "192.168.101.11"

  # config.vm.synced_folder "../data", "/vagrant_data"
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # config.vm.provider "parallels" do |vp|
  #   vp.name = "centos-7.9-vagrant"
  #   vp.memory = "2048"
  # end
  config.vm.provider "vmware_desktop" do |vd|
    vd.name = "centos-7.9-vagrant"
    vd.gui = false
    vd.vmx["memsize"] = "2048"
    vd.vmx["numvcpus"] = "2"
  end

  # ---------------- Provision配置 ----------------
  # Shell
  config.vm.provision "shell", inline: "echo Hello From Vagrant CentOS-7.9 Provision ..."
  # 使用下面的shell来配置Centos7里的yum源，否则后续安装ansible不成功，默认以sudo权限执行
  config.vm.provision "shell", inline: "mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup"
  config.vm.provision "shell", inline: "curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo"
  config.vm.provision "shell", inline: "yum clean all && yum makecache"
  # config.vm.provision "shell", inline: "yum install epel-release -y"
  # CentOS7 使用yum大部分安装的都是 2.9.x 版本的Ansible，因为CentOS-7自带的Python版本是 2.7.5，这个版本比较低
  # config.vm.provision "shell", inline: "yum install ansible -y"
  # config.vm.provision "shell", inline: "ansible-galaxy collection install ansible.posix:1.5.4"
  # Ansible
  # config.vm.provision "ansible_local" do |ansible|
  #   ansible.verbose = true
  #   ansible.compatibility_mode = "2.0"
  #   ansible.playbook = "provisioning-ansible/playbook.yml"
  # end
end
