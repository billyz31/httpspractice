# 🦆 Duck DNS 配置指南

## 📋 你的配置信息
- **IP 地址**: `119.77.135.45`
- **域名前缀**: `billyz`
- **完整域名**: `billyz.duckdns.org`

## 🚀 快速开始步骤

### 1. 注册 Duck DNS 账号
1. 访问 [https://www.duckdns.org](https://www.duckdns.org)
2. 使用 GitHub、Google、Twitter 或 Reddit 账号登录
3. 或者创建新的 Duck DNS 账号

### 2. 获取你的 Token
1. 登录后，在主页找到你的 **Token**
2. Token 格式类似: `abcd1234-5678-90ef-ghij-klmnopqrstuv`
3. 复制保存这个 Token（后面会用到）

### 3. 创建域名
1. 在 "Domains" 区域输入: `billyz`
2. 点击 "Add Domain" 按钮
3. 现在你拥有: `billyz.duckdns.org`

### 4. 手动设置 DNS 记录（可选）
如果你想要立即生效，可以手动设置：
```
域名: billyz.duckdns.org
A 记录: 119.77.135.45
TTL: 自动 (通常 1-5 分钟生效)
```

## 🔧 自动化更新脚本

### Windows PowerShell 脚本
创建 `update-duckdns.ps1`:

```powershell
# Duck DNS 自动更新脚本
$token = "你的Token"
$domain = "billyz"
$ip = "119.77.135.45"

# 更新 Duck DNS
$url = "https://www.duckdns.org/update?domains=$domain&token=$token&ip=$ip"
$response = Invoke-WebRequest -Uri $url

Write-Host "Duck DNS 更新结果: $($response.Content)"
Write-Host "域名: $domain.duckdns.org"
Write-Host "IP 地址: $ip"

# 测试域名解析
$dnsResult = Resolve-DnsName -Name "$domain.duckdns.org" -ErrorAction SilentlyContinue
if ($dnsResult) {
    Write-Host "✅ DNS 解析成功: $($dnsResult.IPAddress)"
} else {
    Write-Host "❌ DNS 解析失败，请等待几分钟"
}
```

### 使用方法：
1. 将 `你的Token` 替换为实际的 Token
2. 在 PowerShell 中运行:
   ```powershell
   .\update-duckdns.ps1
   ```

## 🐳 Docker 容器自动更新

创建 `docker-compose-duckdns.yml`:

```yaml
version: '3.8'

services:
  duckdns-updater:
    image: linuxserver/duckdns
    container_name: duckdns
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Taipei
      - SUBDOMAINS=billyz
      - TOKEN=你的Token
      - LOG_FILE=true
    restart: unless-stopped
```

运行命令:
```bash
docker-compose -f docker-compose-duckdns.yml up -d
```

## 📱 手动更新命令

### 使用 curl (推荐):
```bash
curl "https://www.duckdns.org/update?domains=billyz&token=你的Token&ip=119.77.135.45"
```

### 使用 PowerShell:
```powershell
Invoke-WebRequest -Uri "https://www.duckdns.org/update?domains=billyz&token=你的Token&ip=119.77.135.45"
```

## 🔍 验证设置

### 检查 DNS 解析:
```powershell
# PowerShell
Resolve-DnsName -Name "billyz.duckdns.org"

# 或者使用 nslookup
nslookup billyz.duckdns.org
```

### 测试 HTTP 访问:
```powershell
# 测试 HTTP 连接
Invoke-WebRequest -Uri "http://billyz.duckdns.org" -Method Head

# 或者使用 curl
try {
    curl -I http://billyz.duckdns.org
} catch {
    Write-Host "网站尚未部署"
}
```

## ⚙️ Coolify 配置

当 DNS 设置完成后，在 Coolify 中：

1. **创建新应用** 或编辑现有应用
2. **设置 FQDN**: `billyz.duckdns.org`
3. **启用 HTTPS**: 勾选 "Force HTTPS"
4. **保存配置**: Coolify 会自动处理证书申请

### 预期行为：
- ✅ DNS 解析到 `119.77.135.45`
- ✅ Coolify 检测到域名配置
- ✅ Let's Encrypt 自动申请证书
- ✅ HTTPS 服务在几分钟内就绪

## 🐛 故障排除

### 常见问题：
1. **DNS 解析失败**
   - 等待 5-10 分钟让 DNS 传播
   - 检查 Token 是否正确

2. **证书申请失败**
   - 确保端口 80 和 443 对外开放
   - 验证域名解析正确

3. **更新不生效**
   - 检查 IP 地址是否正确
   - 确认域名拼写正确

### 检查命令：
```powershell
# 检查当前公网 IP
curl -s https://api.ipify.org

# 检查 Duck DNS 当前设置
curl -s "https://www.duckdns.org/update?domains=billyz&token=你的Token&ip="
```

## 📞 支持资源

- **Duck DNS 官网**: https://www.duckdns.org
- **官方文档**: https://duckdns.org/spec.jsp
- **社区支持**: Reddit / Twitter

## 🎯 下一步行动

1. ✅ 注册 Duck DNS 账号
2. ✅ 获取 Token
3. ✅ 创建域名 `billyz.duckdns.org`
4. 🔄 配置 DNS 解析到 `119.77.135.45`
5. 🔜 在 Coolify 中设置 FQDN
6. 🔜 启用 HTTPS 自动配置

---

**最后更新**: 2024年
**域名状态**: 待配置
**IP 地址**: 119.77.135.45 ✅