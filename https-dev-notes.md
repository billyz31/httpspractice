# 建立 HTTPS 網站開發筆記

本筆記整理建立「被瀏覽器信任」的 HTTPS 網站所需的必要項目與完整步驟，以 Coolify + Traefik + Let's Encrypt 為主要路徑，並適用其他反向代理（如 NGINX）。

## 1. 目標與總覽
- 目標：快速、穩定、可維護地上線 HTTPS 服務。
- 方法：容器化應用 + 反向代理 + 自動簽發/續期憑證 + CI/CD。
- 成果：FQDN 能以 `https://` 正常訪問、證書有效、重定向與安全頭生效。

## 2. 必要前置條件（Checklist）
- 伺服器與網路
  - 具公網 IP 的 VPS（建議 Ubuntu 22.04+，≥1 vCPU/2GB RAM）。
  - 防火牆/安全組放行 `80`（ACME HTTP-01 驗證）與 `443`（HTTPS）。
  - 系統時間同步（NTP 正常），避免憑證與握手異常。
- 帳號與權限
  - SSH 金鑰登入（`root` 或具 `sudo` 權限使用者），`~/.ssh/authorized_keys` 權限正確。
- 軟體環境
  - 已安裝 Docker。
  - 已完成 Coolify 安裝並可登入（內置 Traefik 反向代理）。
- 網域與 DNS
  - 取得網域（例如 `yourdomain.com`）。
  - 設定 `A/AAAA` 記錄：將 `app.yourdomain.com` 指向伺服器公網 IP。
  - 待 DNS 傳播完成（`nslookup`/`dig` 驗證）。
- 應用程式
  - 有可部署的 Git 倉庫（GitHub/GitLab），建議提供 `Dockerfile`。
  - 應用監聽 `0.0.0.0:<PORT>`（非僅 `127.0.0.1`）。
  - 健康檢查端點（如 `GET /healthz`）。

## 3. 端到端流程（Step-by-Step）
1) 設定 DNS：建立 `A` 記錄 `app.yourdomain.com -> <SERVER_IP>`。
2) 檢查端口：伺服器外網可達 `80/443`；本機防火牆與雲端安全組均放行。
3) 連接 Coolify：
   - 新增「資源」，連接 Git 倉庫。
   - 設定 FQDN：`app.yourdomain.com`，勾選「強制 HTTPS」。
   - 設定環境變數（如 `PORT=3000`），上游埠指向應用監聽埠。
4) 容器化建置：推送程式碼，Coolify 依 `Dockerfile` 建置與部署。
5) 自動憑證：Traefik 透過 ACME 自動申請與安裝 Let's Encrypt 憑證。
6) 驗證訪問：
   - `curl -I https://app.yourdomain.com` 應回 `200/301`。
   - `openssl s_client -connect app.yourdomain.com:443 -servername app.yourdomain.com -showcerts` 檢視證書鏈與協議。
7) 安全與重定向：確認 HTTP → HTTPS 301 重定向、HSTS 與安全頭生效。
8) 持續交付：設置 CI/CD（如 GitHub Actions）自動測試、建置與重新部署。

## 4. 容器化示例與要點
- 多階段 Dockerfile（Node.js 範例）：
```
# syntax=docker/dockerfile:1
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app ./
RUN npm ci --only=production
EXPOSE 3000
CMD ["node","dist/server.js"]
```
- 要點：
  - 鏡像小、依賴清晰、啟動快速。
  - 應用需監聽 `0.0.0.0`；與 Coolify 上游埠一致。

## 5. Coolify 設定重點
- FQDN：輸入完整網域（如 `app.yourdomain.com`）。
- 強制 HTTPS：開啟，所有 HTTP 自動重定向至 HTTPS。
- 憑證：Traefik 自動簽發/續期（HTTP-01；被 CDN 阻擋時改 DNS-01）。
- 環境變數：於 Coolify 管理（勿存於 Git）。
- Proxy 與健康檢查：上游埠正確、`/healthz` 就緒/存活檢查。

## 6. 安全最佳實踐
- TLS：啟用 TLS 1.2+，優先 TLS 1.3；現代 ECDHE/ECDSA 套件。
- HSTS：逐步增加 `max-age`，確保嚴格傳輸安全（測試環境慎用）。
- 安全頭：CSP、X-Frame-Options、X-Content-Type-Options、Referrer-Policy。
- Cookie：`Secure`、`HttpOnly`、`SameSite` 合理設定。
- Secrets：使用環境變數／秘密管理（Vault），避免寫入 Git。

## 7. 性能優化建議
- 網路層：HTTP/2/3（QUIC）、TLS 會話復用、OCSP Stapling、Brotli/Gzip。
- 靜態加速：合理 Cache-Control；接入 CDN。
- 應用層：資料庫連線池與索引、Redis/記憶體快取、非阻塞程式碼、前端資源分割與圖片優化。
- 指標監控：p95/p99 延遲、錯誤率、RPS、CPU/記憶體利用率。

## 8. 驗證清單（Pre/Post Deploy）
- DNS：`nslookup app.yourdomain.com` 指向正確 IP。
- 端口：外網可達 `80/443`；無端口衝突。
- 連線：`curl -Iv https://app.yourdomain.com` 顯示有效協議與證書鏈。
- 評分：SSL Labs 測試達 A 級或以上。
- 安全頭：CSP/HSTS/Referrer-Policy 等生效。
- 監控：p95 < 500ms、錯誤率 < 0.1%、RPS 達標。

## 9. 常見問題與排障
- 憑證簽發失敗：
  - DNS 未生效或指向錯誤；稍後再試或改 DNS-01。
  - `80/443` 被防火牆/NAT/CDN 攔截；確認放行或關閉橙雲代理。
  - 查看 `coolify-proxy`（Traefik）日誌定位 ACME 錯誤。
- 502/504（上游不可達）：
  - 應用監聽 `127.0.0.1` 或埠錯誤；改為 `0.0.0.0` 並對齊代理設定。
  - 健康檢查失敗；修正 `readiness/liveness` 邏輯。
- 混合內容：
  - 前端與所有資源使用 `https://`；清理硬編碼 `http://`。
- CORS 預檢失敗：
  - 精確允許來源（含端口）；正確處理 `OPTIONS` 與 `Access-Control-Allow-*`。
  - 使用 Cookie 時需 `Access-Control-Allow-Credentials: true` 並限定來源。
- 續期問題：
  - 校準 NTP；避免 Let's Encrypt 速率限制（減少重試、調整策略）。

## 10. 常用命令與小範例
- 連通性：`curl -I https://app.yourdomain.com`
- 證書詳情：`openssl s_client -connect app.yourdomain.com:443 -servername app.yourdomain.com -showcerts`
- HTTP/2 檢測：`curl -I --http2 https://app.yourdomain.com`
- Fastify 健康檢查範例：
```
import Fastify from 'fastify'
const app = Fastify({ logger: true, trustProxy: true })
app.get('/healthz', async () => ({ status: 'ok' }))
app.listen({ port: 3000, host: '0.0.0.0' })
```

— 完 —