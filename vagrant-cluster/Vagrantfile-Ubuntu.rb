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
  config.vm.box = "Ubuntu-22.04"
  # 设置虚拟机的名称
  config.vm.define "ubuntu-22.04-vm"
  # 设置主机名
  config.vm.hostname = "ubuntu-zxt"
  # 设置启动后显示的信息
  config.vm.post_up_message = "Hello Ubuntu-22.04 From Vagrant"

  # config.vm.network "public_network"
  # config.vm.network "private_network", type: "dhcp"
  config.vm.network "private_network", ip: "192.168.101.10"

  # config.vm.synced_folder "../data", "/vagrant_data"
  # config.vm.synced_folder ".", "/vagrant", disabled: true

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # config.vm.provider "parallels" do |vp| 
  #   vp.name = "ubuntu-22.04-vagrant" 
  #   vp.memory = "1536"
  # end
  config.vm.provider "vmware_desktop" do |vd|
    vd.name = "ubuntu-22.04-vagrant" 
    vd.gui = false
    vd.vmx["memsize"] = "2048"
    vd.vmx["numvcpus"] = "2"
  end

  # ---------------- Provision配置 ----------------
  # Shell
  config.vm.provision "shell", inline: "echo Hello From Vagrant Ubuntu-22.04 Provision ..."
  # 使用下面的shell来配置Ubuntu-22.04里的apt源，默认以sudo权限执行
  # 备份源
  config.vm.provision "shell", inline: "mv /etc/apt/sources.list /etc/apt/sources.list.bak"
  # 配置阿里源
  config.vm.provision "shell", inline: "touch /etc/apt/sources.list"
  config.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy main multiverse restricted universe' >> /etc/apt/sources.list"
  config.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main multiverse restricted universe' >> /etc/apt/sources.list"
  config.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy-proposed main multiverse restricted universe' >> /etc/apt/sources.list"
  config.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy-security main multiverse restricted universe' >> /etc/apt/sources.list"
  config.vm.provision "shell", inline: "echo 'deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main multiverse restricted universe' >> /etc/apt/sources.list"
  # 配置ansible的PPA源
  config.vm.provision "shell", inline: "apt-get install software-properties-common"
  config.vm.provision "shell", inline: "apt-add-repository ppa:ansible/ansible"
  config.vm.provision "shell", inline: "apt-get update"
  # 安装ansible，这个基本是最新版本
  #config.vm.provision "shell", inline: "apt-get install -y ansible"
end
