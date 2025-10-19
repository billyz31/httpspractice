# 🦆 Duck DNS 快速更新脚本
# 使用方法: .\fix-dns.ps1 -Token "你的Token"

param(
    [Parameter(Mandatory=$true)]
    [string]$Token
)

$domain = "billyz"
$ip = "72.60.198.67"

Write-Host "🦆 更新 Duck DNS 记录..." -ForegroundColor Green
Write-Host "域名: $domain.duckdns.org"
Write-Host "IP地址: $ip"
Write-Host ""

# 构建更新URL
$updateUrl = "https://www.duckdns.org/update?domains=$domain&token=$Token&ip=$ip"

try {
    # 发送更新请求
    $response = Invoke-WebRequest -Uri $updateUrl -UseBasicParsing
    $result = $response.Content.Trim()
    
    Write-Host "✅ 更新结果: $result" -ForegroundColor Green
    
    if ($result -eq "OK") {
        Write-Host "🎉 Duck DNS 更新成功!" -ForegroundColor Green
        
        # 等待DNS传播
        Write-Host "⏳ 等待DNS传播 (15秒)..."
        Start-Sleep -Seconds 15
        
        # 检查DNS解析
        Write-Host "🔍 检查DNS解析..."
        $dnsResult = nslookup $domain.duckdns.org 2>$null
        
        if ($dnsResult -match $ip) {
            Write-Host "✅ DNS 解析正确! 指向: $ip" -ForegroundColor Green
        } else {
            Write-Host "⚠️  DNS可能还在传播中，请稍后检查" -ForegroundColor Yellow
            Write-Host "当前解析结果:"
            Write-Host $dnsResult
        }
        
    } else {
        Write-Host "❌ 更新失败: $result" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ 网络错误: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎯 你的域名: https://$domain.duckdns.org" -ForegroundColor Cyan
Write-Host "📋 下一步: 在Coolify中配置应用并启用HTTPS" -ForegroundColor Magenta