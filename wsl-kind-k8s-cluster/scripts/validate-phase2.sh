#!/bin/bash
# ==========================================
# Phase 2 验证脚本 - Kind集群健康检查
# ==========================================

set -e

echo "🔍 开始 Phase 2 验证..."
echo ""

# 1. 检查CLI工具
echo "📦 检查 K8s CLI 工具..."
for tool in kubectl kind helm; do
    if command -v $tool &> /dev/null; then
        version=$($tool version --client --short 2>/dev/null || $tool version --short 2>/dev/null)
        echo "   ✅ $tool: $version"
    else
        echo "   ❌ $tool: 未安装"
        exit 1
    fi
done
echo ""

# 2. 检查Kind集群
echo "🔧 检查 Kind 集群..."
clusters=$(kind get clusters 2>/dev/null)
if [ -z "$clusters" ]; then
    echo "   ❌ 没有发现Kind集群"
    exit 1
else
    echo "   ✅ 发现的集群: $clusters"
fi
echo ""

# 3. 检查节点状态
echo "📊 检查节点状态..."
nodes=$(kubectl get nodes --no-headers 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "   ❌ 无法连接到集群API Server"
    exit 1
fi

ready_count=$(echo "$nodes" | grep -c "Ready")
total_count=$(echo "$nodes" | wc -l)

echo "   节点总数: $total_count"
echo "   就绪节点: $ready_count"

if [ $ready_count -eq $total_count ]; then
    echo "   ✅ 所有节点已就绪"
else
    echo "   ⚠️  部分节点未就绪，等待中..."
    kubectl get nodes
fi
echo ""

# 4. 检查系统组件
echo "📦 检查系统组件..."
system_pods=$(kubectl get pods -n kube-system --no-headers 2>/dev/null)
if [ $? -eq 0 ]; then
    running_count=$(echo "$system_pods" | grep -c "Running")
    total_pods=$(echo "$system_pods" | wc -l)
    echo "   运行中: $running_count / $total_pods"
    
    if [ $running_count -lt $total_pods ]; then
        echo "   ⚠️  部分Pod正在启动..."
        kubectl get pods -n kube-system
    else
        echo "   ✅ 所有系统组件运行正常"
    fi
else
    echo "   ⏳ 系统组件尚未部署（将在Phase 3完成）"
fi
echo ""

# 5. 检查kubeconfig
echo "🔑 检查 kubeconfig..."
if [ -f "$HOME/.kube/config" ]; then
    echo "   ✅ WSL2 kubeconfig 存在"
    
    # 检查Windows侧是否可访问
    if [ -f "/mnt/c/Users/$USER/.kube/config" ]; then
        echo "   ✅ Windows kubeconfig 已同步"
    else
        echo "   ⚠️  Windows kubeconfig 未同步，请手动复制:"
        echo "      cp ~/.kube/config /mnt/c/Users/\$USER/.kube/config"
    fi
else
    echo "   ❌ kubeconfig 文件不存在"
    exit 1
fi
echo ""

# 6. 端口映射检查
echo "🔌 检查端口映射..."
for port in 80 443; do
    if ss -tlnp | grep -q ":${port} "; then
        echo "   ✅ 端口 $port 已监听"
    else
        echo "   ⚠️  端口 $port 未监听（可能在Phase 3配置）"
    fi
done
echo ""

echo "═══════════════════════════════════════════"
echo "  ✅ Phase 2 验证完成！"
echo "═══════════════════════════════════════════"
echo ""
echo "🎯 下一步："
echo "   执行 Phase 3 部署基础设施组件："
echo "   ansible-playbook playbooks/phase3-infra.yml"
echo ""
