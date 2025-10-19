import { useState, useEffect } from 'react'
import './App.css'

function App() {
  const [message, setMessage] = useState('')
  const [health, setHealth] = useState(null)
  const [loading, setLoading] = useState(false)
  const [inputText, setInputText] = useState('')

  // 获取健康状态
  const fetchHealth = async () => {
    try {
      const response = await fetch('/api/health')
      const data = await response.json()
      setHealth(data)
    } catch (error) {
      console.error('Health check failed:', error)
      setHealth({ status: 'ERROR', error: error.message })
    }
  }

  // 获取消息
  const fetchMessage = async () => {
    setLoading(true)
    try {
      const response = await fetch('/api/message')
      const data = await response.json()
      setMessage(data.message)
    } catch (error) {
      console.error('Failed to fetch message:', error)
      setMessage('无法连接到服务器')
    }
    setLoading(false)
  }

  // 发送回显消息
  const sendEcho = async () => {
    if (!inputText.trim()) return
    
    setLoading(true)
    try {
      const response = await fetch('/api/echo', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ message: inputText })
      })
      const data = await response.json()
      setMessage(data.echoed)
      setInputText('')
    } catch (error) {
      console.error('Echo failed:', error)
      setMessage('回显请求失败')
    }
    setLoading(false)
  }

  // 组件挂载时获取健康状态
  useEffect(() => {
    fetchHealth()
    fetchMessage()
  }, [])

  return (
    <div className="app">
      <header className="app-header">
        <h1>🔒 HTTPS 全栈应用演示</h1>
        <p>React前端 + Node.js后端 + Coolify部署</p>
      </header>

      <main className="app-main">
        {/* 健康状态显示 */}
        <section className="health-section">
          <h2>服务器状态</h2>
          {health ? (
            <div className={`health-status ${health.status === 'OK' ? 'healthy' : 'unhealthy'}`}>
              <span>状态: {health.status}</span>
              <span>环境: {health.environment}</span>
              <span>HTTPS: {health.https ? '✅' : '❌'}</span>
              <span>时间: {new Date(health.timestamp).toLocaleString('zh-TW')}</span>
            </div>
          ) : (
            <p>检查服务器状态中...</p>
          )}
        </section>

        {/* 消息显示 */}
        <section className="message-section">
          <h2>API 消息</h2>
          <div className="message-box">
            {loading ? (
              <p>加载中...</p>
            ) : (
              <p className="message-text">{message || '点击按钮获取消息'}</p>
            )}
          </div>
          <button 
            onClick={fetchMessage} 
            disabled={loading}
            className="btn btn-primary"
          >
            获取消息
          </button>
        </section>

        {/* 回显输入 */}
        <section className="echo-section">
          <h2>消息回显</h2>
          <div className="input-group">
            <input
              type="text"
              value={inputText}
              onChange={(e) => setInputText(e.target.value)}
              placeholder="输入要回显的消息"
              className="text-input"
              disabled={loading}
            />
            <button 
              onClick={sendEcho} 
              disabled={loading || !inputText.trim()}
              className="btn btn-secondary"
            >
              发送
            </button>
          </div>
        </section>

        {/* 部署信息 */}
        <section className="deploy-info">
          <h2>部署信息</h2>
          <div className="info-grid">
            <div className="info-item">
              <strong>前端技术</strong>
              <span>React 18 + Vite</span>
            </div>
            <div className="info-item">
              <strong>后端技术</strong>
              <span>Node.js + Express</span>
            </div>
            <div className="info-item">
              <strong>部署平台</strong>
              <span>Coolify + Docker</span>
            </div>
            <div className="info-item">
              <strong>HTTPS</strong>
              <span>Let's Encrypt 自动证书</span>
            </div>
          </div>
        </section>
      </main>

      <footer className="app-footer">
        <p>🚀 使用 Coolify 轻松部署 HTTPS 应用</p>
      </footer>
    </div>
  )
}

export default App