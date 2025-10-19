# 高效开发与部署 HTTPS 服务指南

本指南面向希望快速、稳定地上线 HTTPS Web 服务的团队与个人，聚焦“高效开发 + 安全上线 + 持续优化”。示例以 Coolify + Traefik + Let's Encrypt 为主，亦适用于其他反向代理（如 NGINX）。

## 目录
1. 概述与目标
2. 快速上手（5 分钟完成 HTTPS）
3. 部署流程（端到端）
4. 最佳实践（安全、可靠、可维护）
5. 性能优化建议（网络层 + 应用层）
6. 常见问题解决方案（实战排障）
7. 验证清单（上线前后自检）
8. 示例配置片段（可复用模板）

---

## 1. 概述与目标
- 统一方法论：以“容器化 + 反向代理 + 自动证书 + CI/CD”为核心。
- 强调实践：可直接复用的配置、命令与清单。
- 结果导向：更快上线、更少故障、更高可见性与安全性。

---

## 2. 快速上手（5 分钟完成 HTTPS）
- 步骤概览：域名与 DNS → 反向代理与证书 → 部署应用 → 验证。
- 最小可行部署（MVP）：
  1) 购买域名并将 `app.yourdomain.com` 的 A 记录指向 VPS 公网 IP。
  2) 在 Coolify 中创建新资源，连接 Git 仓库，选择构建方式（如 Node.js）。
  3) 设置 FQDN 为 `app.yourdomain.com`，启用“强制 HTTPS”。
  4) 一键部署，Coolify/Traefik 自动申请并安装 Let's Encrypt 证书。
  5) 验证：`curl -I https://app.yourdomain.com` 返回 `200/301` 且证书有效。

---

## 3. 部署流程（端到端）

### 3.1 环境准备
- 打开端口：`80`（HTTP-01 验证）、`443`（HTTPS）。
- 时间同步：确保服务器 NTP 正常，避免证书与会话问题。
- Docker 与平台：安装 Docker 并完成 Coolify 安装（已内置 Traefik）。
- 防火墙：放行 `80/443`，数据库端口仅在内网或特定来源开放。

### 3.2 应用容器化
- 使用多阶段构建，保证镜像小、启动快、依赖清晰。
- Node.js 示例 Dockerfile（多阶段）：
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

### 3.3 反向代理与证书
- 在 Coolify 资源设置中配置 FQDN，开启“强制 HTTPS”。
- 证书自动化：Traefik 通过 ACME（HTTP-01/DNS-01）自动申请与续期。
- 建议开启：HSTS（严格传输安全）、OCSP Stapling（证书状态优化）。

### 3.4 CI/CD（建议 GitHub Actions）
- 触发：`push` 到 `main`/`develop` 分支。
- 阶段：安装依赖 → 测试 → 构建 → 部署（触发 Coolify 更新或 Webhook）。
- 最小工作流示例：
```
name: ci
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci && npm test && npm run build
```

---

## 4. 最佳实践（安全、可靠、可维护）

### 4.1 安全加固
- TLS 版本：启用 TLS 1.2+，优先 TLS 1.3。
- 加密套件：使用现代 ECDHE/ECDSA，禁用过时算法。
- HSTS：开启并逐步增加 `max-age`（谨慎，避免测试环境误用）。
- Cookie：`Secure` + `HttpOnly` + `SameSite` 合理设置。
- 安全头：CSP、X-Frame-Options、X-Content-Type-Options、Referrer-Policy。
- Secrets 管理：不写入 Git；运行时注入环境变量或使用 Vault。

### 4.2 可靠性与可维护性
- 健康检查：提供 `GET /healthz`（就绪/存活探针）。
- 日志：结构化日志（JSON），保留请求 ID 与关键上下文。
- 资源限制：容器 CPU/内存限额，避免抢占与雪崩。
- 回滚策略：保留上一个可用镜像，失败自动回滚。
- 灰度/金丝雀发布：逐步放量，降低上线风险。

---

## 5. 性能优化建议（网络层 + 应用层）

### 5.1 网络层
- HTTP/2/3（QUIC）：由 Traefik/代理启用，改善并发与延迟。
- TLS 会话复用与 0-RTT：提升握手效率（0-RTT 谨慎使用）。
- OCSP Stapling：降低证书状态查询延迟。
- 压缩：开启 Brotli/Gzip；文本资源优先 Brotli。
- 缓存与 CDN：静态资源下发合理缓存头，接入 CDN。

### 5.2 应用层
- 连接池与索引：数据库使用连接池，关键查询加索引。
- 缓存策略：Redis/内存缓存，降低数据库压力。
- 代码优化：减少阻塞操作；前端代码分割与图片优化。
- 监控指标：关注 p95/p99 延迟、错误率、RPS、资源利用率。

---

## 6. 常见问题解决方案（实战排障）

### 6.1 证书签发失败
- DNS 未生效或错误：A/AAAA 记录指向不正确；等待传播。
- 端口被占用/阻断：`80/443` 未开放或被防火墙/NAT 拦截。
- CDN/代理干扰：如 Cloudflare 橙云代理导致 HTTP-01 失败，临时关闭或改用 DNS-01。
- 查看日志：检查 `coolify-proxy`（Traefik）容器日志，定位 ACME 错误。

### 6.2 续期失败
- 时间偏差：服务器时钟不准，校准 NTP。
- 速率限制：Let's Encrypt 触发频率限制，减少重试或更换域名策略。

### 6.3 502/504、上游不可达
- 上游端口错误：应用监听端口与代理配置不一致。
- 监听地址错误：确保监听 `0.0.0.0` 而非仅 `127.0.0.1`。
- 健康检查失败：修复 `readiness/liveness` 检查逻辑。
- 观察应用日志：`docker logs <container_name>` 查异常。

### 6.4 Mixed Content（混合内容）
- 所有资源（API、图片、脚本、样式）必须使用 `https://`。
- 前端构建产物中的硬编码 `http://` 链接需清理。

### 6.5 CORS/预检失败
- 允许来源：精确到域名（含端口），避免 `*`。
- 响应预检：正确处理 `OPTIONS`，返回 `Access-Control-Allow-*`。
- 凭证：如使用 Cookie，`Access-Control-Allow-Credentials: true` 且指定来源。

---

## 7. 验证清单（上线前后自检）
- DNS：`nslookup app.yourdomain.com` 指向正确 IP，A/AAAA 均验证。
- 端口：外网可访问 `80/443`；无端口冲突。
- 证书：`curl -Iv https://app.yourdomain.com` 显示有效链与协议版本。
- 评分：使用 SSL Labs 检测，目标 A（或以上）。
- 安全头：CSP/HSTS/Referrer-Policy 等生效。
- 监控：p95 < 500ms、错误率 < 0.1%、RPS 达标。

---

## 8. 示例配置片段（可复用模板）

### 8.1 Node.js（Fastify）服务示例
```
import Fastify from 'fastify'
const app = Fastify({ logger: true, trustProxy: true })
app.get('/healthz', async () => ({ status: 'ok' }))
app.listen({ port: 3000, host: '0.0.0.0' })
```

### 8.2 快速验证命令
- 基本连通：`curl -I https://app.yourdomain.com`
- 证书详情：`openssl s_client -connect app.yourdomain.com:443 -servername app.yourdomain.com -showcerts`
- HTTP/2 检测：`curl -I --http2 https://app.yourdomain.com`

---

以上内容可作为“高效开发与部署 HTTPS”的标准作业模板。建议在项目初始化阶段即对照本指南配置，持续保持安全与性能基线。