# 🦆 Duck DNS 自动更新脚本
# 使用方法: .\update-duckdns.ps1 -Token "你的Token"

param(
    [Parameter(Mandatory=$false)]
    [string]$Token = "",
    [Parameter(Mandatory=$false)]
    [string]$Domain = "billyz",
    [Parameter(Mandatory=$false)]
    [string]$IP = "119.77.135.45"
)

Write-Host "🦆 Duck DNS 更新工具" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green

# 如果没有提供Token，提示用户输入
if ([string]::IsNullOrEmpty($Token)) {
    $Token = Read-Host "请输入你的 Duck DNS Token"
}

# 验证输入
if ([string]::IsNullOrEmpty($Token)) {
    Write-Host "❌ 错误: 必须提供 Token" -ForegroundColor Red
    exit 1
}

Write-Host "📋 配置信息:" -ForegroundColor Yellow
Write-Host "   域名: $Domain.duckdns.org"
Write-Host "   IP地址: $IP"
Write-Host "   Token: $Token"
Write-Host ""

# 构建更新URL
$updateUrl = "https://www.duckdns.org/update?domains=$Domain&token=$Token&ip=$IP"

Write-Host "🔄 正在更新 Duck DNS..." -ForegroundColor Cyan
try {
    # 发送更新请求
    $response = Invoke-WebRequest -Uri $updateUrl -ErrorAction Stop
    $result = $response.Content.Trim()
    
    Write-Host "✅ 更新结果: $result" -ForegroundColor Green
    
    if ($result -eq "OK") {
        Write-Host "🎉 Duck DNS 更新成功!" -ForegroundColor Green
    } else {
        Write-Host "❌ 更新失败: $result" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ 网络错误: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🔍 验证 DNS 解析..." -ForegroundColor Cyan

# 等待一下让DNS更新
try {
    Write-Host "⏳ 等待DNS传播 (10秒)..."
    Start-Sleep -Seconds 10
    
    # 检查DNS解析
    $dnsResult = Resolve-DnsName -Name "$Domain.duckdns.org" -ErrorAction Stop
    
    if ($dnsResult) {
        $resolvedIP = $dnsResult.IPAddress
        Write-Host "✅ DNS 解析成功!" -ForegroundColor Green
        Write-Host "   解析到的IP: $resolvedIP"
        Write-Host "   期望的IP: $IP"
        
        if ($resolvedIP -eq $IP) {
            Write-Host "🎯 IP地址匹配正确!" -ForegroundColor Green
        } else {
            Write-Host "⚠️  IP地址不匹配，可能需要更多时间传播" -ForegroundColor Yellow
        }
    }
    
} catch {
    Write-Host "❌ DNS 解析失败: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "ℹ️  这可能是正常的，DNS传播可能需要几分钟时间" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🌐 测试 HTTP 访问..." -ForegroundColor Cyan

try {
    $httpTest = Invoke-WebRequest -Uri "http://$Domain.duckdns.org" -Method Head -TimeoutSec 10 -ErrorAction Stop
    Write-Host "✅ HTTP 访问成功 (状态码: $($httpTest.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "ℹ️  HTTP 访问失败: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   这可能是正常的，网站可能尚未部署" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 下一步操作:" -ForegroundColor Magenta
Write-Host "1. 登录 Coolify 控制面板"
Write-Host "2. 创建或编辑应用"
Write-Host "3. 设置 FQDN: $Domain.duckdns.org"
Write-Host "4. 启用 'Force HTTPS'"
Write-Host "5. 保存并部署"

Write-Host ""
Write-Host "🎯 你的域名: http://$Domain.duckdns.org" -ForegroundColor Cyan
Write-Host "🎯 即将可用的HTTPS: https://$Domain.duckdns.org" -ForegroundColor Cyan

# 保存配置供以后使用
$config = @{
    Domain = $Domain
    IP = $IP
    Token = $Token
    LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
}

$config | ConvertTo-Json | Out-File -FilePath "duckdns-config.json" -Encoding UTF8
Write-Host "💾 配置已保存到: duckdns-config.json" -ForegroundColor Green