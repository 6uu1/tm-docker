#!/usr/bin/env python3
import os
import subprocess
import time
from flask import Flask, render_template_string, jsonify
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# 从环境变量获取 token (Hugging Face Spaces Secrets)
TRAFFMONETIZER_TOKEN = os.environ.get('TRAFFMONETIZER_TOKEN', '')

def get_traffmonetizer_status():
    """获取 traffmonetizer 服务状态"""
    try:
        # 检查进程是否运行
        result = subprocess.run(['pgrep', '-f', 'traffmonetizer'], 
                              capture_output=True, text=True)
        if result.returncode == 0:
            return {"running": True, "message": "运行中", "pid": result.stdout.strip()}
        else:
            return {"running": False, "message": "未运行"}
    except Exception as e:
        return {"running": False, "message": f"状态检查失败: {str(e)}"}

# 读取 HTML 模板
def get_html_template():
    try:
        with open('/home/user/app/index.html', 'r', encoding='utf-8') as f:
            return f.read()
    except FileNotFoundError:
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>个人主页</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 40px; }
                .container { max-width: 800px; margin: 0 auto; }
                .status { padding: 10px; margin: 20px 0; border-radius: 5px; }
                .status.running { background-color: #d4edda; color: #155724; }
                .status.stopped { background-color: #f8d7da; color: #721c24; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>欢迎访问我的个人主页</h1>
                <p>这是一个简单的个人展示页面。</p>
                <div id="status" class="status">系统状态检查中...</div>
            </div>
            <script>
                setInterval(function() {
                    fetch('/status')
                        .then(response => response.json())
                        .then(data => {
                            const statusDiv = document.getElementById('status');
                            statusDiv.textContent = '系统运行正常';
                            statusDiv.className = 'status running';
                        })
                        .catch(error => {
                            const statusDiv = document.getElementById('status');
                            statusDiv.textContent = '系统状态检查失败';
                            statusDiv.className = 'status stopped';
                        });
                }, 5000);
            </script>
        </body>
        </html>
        """

@app.route('/')
def index():
    """主页路由"""
    html_content = get_html_template()
    return render_template_string(html_content)

@app.route('/status')
def status():
    """状态检查 API"""
    traffmonetizer_status = get_traffmonetizer_status()
    return jsonify({
        "status": "ok",
        "traffmonetizer": traffmonetizer_status,
        "token_configured": bool(TRAFFMONETIZER_TOKEN),
        "timestamp": time.time()
    })

@app.route('/health')
def health():
    """健康检查"""
    return jsonify({"status": "healthy"})

@app.route('/logs')
def logs():
    """查看日志（调试用）"""
    try:
        with open('/var/log/traffmonetizer.out.log', 'r') as f:
            traffmonetizer_logs = f.read()
    except:
        traffmonetizer_logs = "无法读取日志"
    
    return jsonify({
        "traffmonetizer_logs": traffmonetizer_logs[-1000:]  # 只返回最后1000个字符
    })

if __name__ == '__main__':
    # 启动 Flask 应用
    port = int(os.environ.get('PORT', 7860))
    app.run(host='0.0.0.0', port=port, debug=False)

