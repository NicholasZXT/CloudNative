#!/bin/bash
# ==========================================
# K8s CLI 工具离线下载脚本
# 在Windows PowerShell或WSL2中运行此脚本
# ==========================================

set -e

# 从all.yml中读取版本信息（这里使用默认值，实际使用时可以解析yaml）
KUBECTL_VERSION="v1.31.1"
KIND_VERSION="v0.24.0"
HELM_VERSION="v3.16.2"
ARCH="amd64"

# 下载目录
DOWNLOAD_DIR="${1:-./k8s-cli-offline}"

echo "📦 K8s CLI 离线下载工具"
echo "═══════════════════════════════════════"
echo "kubectl: $KUBECTL_VERSION"
echo "kind:    $KIND_VERSION"
echo "helm:    $HELM_VERSION"
echo "架构:    $ARCH"
echo "下载目录: $DOWNLOAD_DIR"
echo "═══════════════════════════════════════"
echo ""

# 创建下载目录
mkdir -p "$DOWNLOAD_DIR"
cd "$DOWNLOAD_DIR"

# 下载 kubectl
echo "⬇️  下载 kubectl..."
if [ ! -f "kubectl" ]; then
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
    chmod +x kubectl
    echo "   ✅ kubectl 下载完成"
else
    echo "   ⏭️  kubectl 已存在，跳过"
fi

# 验证 kubectl
if command -v ./kubectl &> /dev/null; then
    KUBECTL_VER=$(./kubectl version --client --short 2>/dev/null || ./kubectl version --client 2>/dev/null | head -1)
    echo "   版本: $KUBECTL_VER"
fi
echo ""

# 下载 kind
echo "⬇️  下载 kind..."
if [ ! -f "kind" ]; then
    curl -LO "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
    mv "kind-linux-${ARCH}" kind
    chmod +x kind
    echo "   ✅ kind 下载完成"
else
    echo "   ⏭️  kind 已存在，跳过"
fi

# 验证 kind
if command -v ./kind &> /dev/null; then
    KIND_VER=$(./kind version 2>/dev/null || echo "unknown")
    echo "   版本: $KIND_VER"
fi
echo ""

# 下载 helm
echo "⬇️  下载 helm..."
HELM_FILE="helm-${HELM_VERSION}-linux-${ARCH}.tar.gz"
if [ ! -f "$HELM_FILE" ]; then
    curl -LO "https://get.helm.sh/${HELM_FILE}"
    echo "   ✅ helm 下载完成"
else
    echo "   ⏭️  helm 已存在，跳过"
fi

# 验证 helm 压缩包
if [ -f "$HELM_FILE" ]; then
    echo "   文件: $HELM_FILE"
    ls -lh "$HELM_FILE" | awk '{print "   大小: " $5}'
fi
echo ""

# 输出配置示例
echo "═══════════════════════════════════════"
echo "✅ 所有文件下载完成！"
echo ""
echo "📁 文件位置: $(pwd)"
echo ""
echo "📝 Ansible 配置示例:"
echo ""
echo "编辑 ansible/group_vars/all.yml，设置："
echo ""
echo "k8s_cluster_local:"
echo "  from_local: true"
echo "  kubectl: \"$(pwd)/kubectl\""
echo "  kind: \"$(pwd)/kind\""
echo "  helm: \"$(pwd)/${HELM_FILE}\""
echo ""
echo "💡 提示："
echo "   - 如果在WSL2中使用，路径格式为: /mnt/c/Users/YourName/..."
echo "   - 如果在Windows PowerShell中使用，需要将文件复制到WSL2可访问的位置"
echo "═══════════════════════════════════════"
echo ""
