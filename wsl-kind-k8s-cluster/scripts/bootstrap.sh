#!/usr/bin/env bash
# =============================================================================
# Phase 1 Bootstrap: Install Ansible + Docker CE on WSL2 Ubuntu
# 
# 职责边界: 仅安装 Ansible 和 Docker 两个前置依赖
# 执行方式: chmod +x bootstrap.sh && sudo ./bootstrap.sh
# 幂等性:   支持重复执行，已安装的组件会自动跳过
# =============================================================================
set -euo pipefail

# -------------------------------------------
# 0. 预检查
# -------------------------------------------
if [[ $EUID -ne 0 ]]; then
    echo "❌ 请使用 sudo 执行此脚本: sudo $0"
    exit 1
fi

# 获取实际调用用户（sudo 下 SUDO_USER 为真实用户）
REAL_USER="${SUDO_USER:-$USER}"
echo "👤 目标用户: ${REAL_USER}"

# -------------------------------------------
# 1. 更新包索引 & 安装基础工具
# -------------------------------------------
echo ""
echo "📦 [1/4] 更新包索引并安装基础依赖..."
export DEBIAN_FRONTEND=noninteractive

# 1.1 更新包索引
echo "  📋 更新包索引..."
apt-get update -qq
echo "  ✅ 包索引更新完成"

# 1.2 安装核心基础工具
echo "  🔧 安装核心基础工具 (ca-certificates, curl, gnupg, lsb-release, python3, python3-pip, python3-venv, git, unzip)..."
apt-get install -y -qq \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    python3 \
    python3-pip \
    python3-venv \
    git \
    unzip > /dev/null
echo "  ✅ 核心基础工具安装完成"

# 1.3 安装 rsync（文件同步工具）
echo "  🔄 安装 rsync..."
apt-get install -y -qq rsync > /dev/null
RSYNC_VER=$(rsync --version 2>/dev/null | head -1 || echo "未知")
echo "  ✅ rsync 安装完成: ${RSYNC_VER}"

# 1.4 安装网络工具（net-tools 提供 ifconfig 等命令）
echo "  🌐 安装网络工具 (net-tools)..."
apt-get install -y -qq net-tools > /dev/null
echo "  ✅ 网络工具安装完成 (ifconfig, netstat, route 等)"

echo "✅ 基础依赖就绪"

# -------------------------------------------
# 2. 安装 Docker CE (国内镜像源 + 版本回退)
# -------------------------------------------
echo ""
echo "🐳 [2/4] 安装 Docker CE..."
if command -v docker &> /dev/null; then
    DOCKER_VER=$(docker --version | awk '{print $3}' | tr -d ',')
    echo "⏭️  Docker 已安装 (${DOCKER_VER})，跳过"
else
    # === 版本代号回退逻辑 ===
    # Docker 官方/镜像源可能尚未支持最新开发版 Ubuntu
    # 当检测到未支持版本时，自动回退到最近的 LTS
    UBUNTU_CODENAME=$(lsb_release -cs)
    SUPPORTED_CODENAMES=("jammy" "noble")  # 22.04, 24.04
    
    DOCKER_CODENAME="${UBUNTU_CODENAME}"
    if [[ ! " ${SUPPORTED_CODENAMES[*]} " =~ " ${UBUNTU_CODENAME} " ]]; then
        echo "⚠️  Ubuntu ${UBUNTU_CODENAME} 尚未被 Docker 仓库支持，回退到 noble (24.04)"
        DOCKER_CODENAME="noble"
    fi

    # === 使用清华 TUNA 镜像源（国内稳定） ===
    DOCKER_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu"
    
    install -m 0755 -d /etc/apt/keyrings
    
    # 带重试的 GPG key 下载
    MAX_RETRIES=3
    for i in $(seq 1 $MAX_RETRIES); do
        if curl -fsSL --retry 3 --retry-delay 5 \
            "${DOCKER_MIRROR}/gpg" | \
            gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null; then
            chmod a+r /etc/apt/keyrings/docker.gpg
            echo "✅ GPG key 下载成功 (尝试 ${i}/${MAX_RETRIES})"
            break
        fi
        if [[ $i -eq $MAX_RETRIES ]]; then
            echo "❌ GPG key 下载失败，请检查网络连接"
            exit 1
        fi
        echo "⚠️  GPG key 下载失败，${i}/${MAX_RETRIES} 次重试..."
        sleep 3
    done

    # 写入镜像源配置
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      ${DOCKER_MIRROR} \
      ${DOCKER_CODENAME} stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "📋 Docker 源: ${DOCKER_MIRROR} (${DOCKER_CODENAME})"
    
    apt-get update -qq
    apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-compose-plugin > /dev/null
    echo "✅ Docker CE 安装完成"
fi

# -------------------------------------------
# 3. 安装 Ansible (pip, 非系统包)
# -------------------------------------------
echo ""
echo "🔧 [3/4] 安装 Ansible..."
if command -v ansible &> /dev/null; then
    ANSIBLE_VER=$(ansible --version | head -1 | awk '{print $3}')
    echo "⏭️  Ansible 已安装 (${ANSIBLE_VER})，跳过"
else
    # 使用 pip 安装以获得最新版本，避免 Ubuntu 自带版本过旧
    pip3 install --quiet --break-system-packages ansible
    echo "✅ Ansible 安装完成"
fi

# -------------------------------------------
# 4. 将用户加入 docker 组并配置免密 sudo
# -------------------------------------------
echo ""
echo "👥 [4/4] 配置用户权限..."
if groups "${REAL_USER}" | grep -q docker; then
    echo "⏭️  用户 ${REAL_USER} 已在 docker 组中,跳过"
else
    usermod -aG docker "${REAL_USER}"
    echo "✅ 已将 ${REAL_USER} 加入 docker 组"
    echo "⚠️  注意: 需要重新登录 WSL2 或执行 'newgrp docker' 使组权限生效"
fi

# 配置免密 sudo
echo ""
echo "🔑 配置免密 sudo..."
SUDOERS_FILE="/etc/sudoers.d/${REAL_USER}"
if [[ -f "${SUDOERS_FILE}" ]]; then
    echo "⏭️  用户 ${REAL_USER} 的免密 sudo 配置已存在,跳过"
else
    echo "${REAL_USER} ALL=(ALL) NOPASSWD: ALL" > "${SUDOERS_FILE}"
    chmod 0440 "${SUDOERS_FILE}"
    echo "✅ 已为用户 ${REAL_USER} 配置免密 sudo"
    echo "⚠️  注意: 下次执行 sudo 命令时将不再需要输入密码"
fi

# -------------------------------------------
# 5. 启动 Docker 服务 (WSL2 systemd 兼容)
# -------------------------------------------
echo ""
echo "🚀 启动 Docker 服务..."
if pidof systemd > /dev/null 2>&1; then
    # systemd 模式
    systemctl enable --now docker > /dev/null 2>&1 || true
    echo "✅ Docker 已通过 systemd 启动"
else
    # 非 systemd 模式 (传统 WSL2 init)
    if ! pgrep -x dockerd > /dev/null; then
        nohup dockerd > /var/log/dockerd.log 2>&1 &
        sleep 3
        echo "✅ Docker 已通过手动进程启动"
    else
        echo "⏭️  Docker daemon 已在运行"
    fi
fi

# -------------------------------------------
# 6. 最终验证
# -------------------------------------------
echo ""
echo "============================================="
echo "🎉 Phase 1 Bootstrap 完成!"
echo "============================================="
echo ""
echo "验证结果:"
printf "  %-12s %s\n" "Docker:" "$(docker --version 2>/dev/null || echo '❌ 未找到')"
printf "  %-12s %s\n" "Ansible:" "$(ansible --version 2>/dev/null | head -1 || echo '❌ 未找到')"
printf "  %-12s %s\n" "Python:"  "$(python3 --version 2>/dev/null || echo '❌ 未找到')"
echo ""
echo "下一步:"
echo "  1. 如果刚加入 docker 组，请执行: newgrp docker"
echo "  2. 进入 ansible/ 目录执行 Phase 1 Playbook:"
echo "     cd ansible && ansible-playbook playbooks/phase1-init.yml"
echo "============================================="