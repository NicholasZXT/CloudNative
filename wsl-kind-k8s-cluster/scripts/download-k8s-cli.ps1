# ==========================================
# K8s CLI 工具离线下载脚本 (PowerShell版本)
# 在Windows PowerShell中运行此脚本
# ==========================================

# 版本配置
$KUBECTL_VERSION = "v1.31.1"
$KIND_VERSION = "v0.24.0"
$HELM_VERSION = "v3.16.2"
$ARCH = "amd64"

# 下载目录（默认在当前目录下创建k8s-cli-offline文件夹）
$DOWNLOAD_DIR = if ($args[0]) { $args[0] } else { ".\k8s-cli-offline" }

Write-Host "📦 K8s CLI 离线下载工具 (PowerShell)" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "kubectl: $KUBECTL_VERSION"
Write-Host "kind:    $KIND_VERSION"
Write-Host "helm:    $HELM_VERSION"
Write-Host "架构:    $ARCH"
Write-Host "下载目录: $DOWNLOAD_DIR"
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# 创建下载目录
if (!(Test-Path $DOWNLOAD_DIR)) {
    New-Item -ItemType Directory -Path $DOWNLOAD_DIR | Out-Null
}
Set-Location $DOWNLOAD_DIR
$DOWNLOAD_DIR = (Get-Location).Path

# 下载 kubectl (Linux版本，用于WSL2)
Write-Host "⬇️  下载 kubectl (Linux amd64)..." -ForegroundColor Yellow
$kubectlPath = Join-Path $DOWNLOAD_DIR "kubectl"
if (!(Test-Path $kubectlPath)) {
    $url = "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl"
    Invoke-WebRequest -Uri $url -OutFile $kubectlPath -UseBasicParsing
    Write-Host "   ✅ kubectl 下载完成" -ForegroundColor Green
} else {
    Write-Host "   ⏭️  kubectl 已存在，跳过" -ForegroundColor Gray
}
Write-Host ""

# 下载 kind (Linux版本，用于WSL2)
Write-Host "⬇️  下载 kind (Linux amd64)..." -ForegroundColor Yellow
$kindPath = Join-Path $DOWNLOAD_DIR "kind"
if (!(Test-Path $kindPath)) {
    $url = "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
    Invoke-WebRequest -Uri $url -OutFile "$kind.tmp" -UseBasicParsing
    Move-Item "$kind.tmp" $kindPath
    Write-Host "   ✅ kind 下载完成" -ForegroundColor Green
} else {
    Write-Host "   ⏭️  kind 已存在，跳过" -ForegroundColor Gray
}
Write-Host ""

# 下载 helm (Linux压缩包)
Write-Host "⬇️  下载 helm (Linux amd64 tar.gz)..." -ForegroundColor Yellow
$helmFile = "helm-${HELM_VERSION}-linux-${ARCH}.tar.gz"
$helmPath = Join-Path $DOWNLOAD_DIR $helmFile
if (!(Test-Path $helmPath)) {
    $url = "https://get.helm.sh/$helmFile"
    Invoke-WebRequest -Uri $url -OutFile $helmPath -UseBasicParsing
    Write-Host "   ✅ helm 下载完成" -ForegroundColor Green
} else {
    Write-Host "   ⏭️  helm 已存在，跳过" -ForegroundColor Gray
}

if (Test-Path $helmPath) {
    $fileSize = (Get-Item $helmPath).Length / 1MB
    Write-Host "   文件: $helmFile" -ForegroundColor Gray
    Write-Host ("   大小: {0:N2} MB" -f $fileSize) -ForegroundColor Gray
}
Write-Host ""

# 输出配置示例
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "✅ 所有文件下载完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📁 文件位置: $DOWNLOAD_DIR" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 下一步操作：" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. 将这些文件复制到WSL2可访问的位置，例如：" -ForegroundColor White
Write-Host "   wsl cp $kubectlPath /home/`$USER/k8s-cli/" -ForegroundColor Gray
Write-Host "   wsl cp $kindPath /home/`$USER/k8s-cli/" -ForegroundColor Gray
Write-Host "   wsl cp $helmPath /home/`$USER/k8s-cli/" -ForegroundColor Gray
Write-Host ""
Write-Host "2. 编辑 ansible/group_vars/all.yml，设置：" -ForegroundColor White
Write-Host ""
Write-Host "k8s_cluster_local:" -ForegroundColor Yellow
Write-Host "  from_local: true" -ForegroundColor Yellow
Write-Host ("  kubectl: `"/home/`$USER/k8s-cli/kubectl`"" -ForegroundColor Yellow
Write-Host ("  kind: `"/home/`$USER/k8s-cli/kind`"" -ForegroundColor Yellow
Write-Host ("  helm: `"/home/`$USER/k8s-cli/$helmFile`"" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. 执行Ansible Playbook：" -ForegroundColor White
Write-Host "   cd wsl-kind-k8s-cluster/ansible" -ForegroundColor Gray
Write-Host "   ansible-playbook playbooks/phase2-kind.yml --tags cli" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 提示：" -ForegroundColor Cyan
Write-Host "   - 这些是Linux amd64版本的文件，不能直接在Windows上运行" -ForegroundColor Gray
Write-Host "   - 必须通过WSL2访问或在WSL2内部使用" -ForegroundColor Gray
Write-Host "   - 路径需要使用WSL2的绝对路径格式（如 /home/user/...）" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
