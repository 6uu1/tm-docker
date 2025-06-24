# 基于 traffmonetizer 官方镜像
FROM traffmonetizer/cli_v2:latest
ENTRYPOINT []

# 设置用户权限 (Hugging Face Spaces 要求)
USER root
RUN apk update && apk add --no-cache shadow python3 py3-pip supervisor && rm -rf /var/cache/apk/*
RUN useradd -m -u 1000 user

# 创建应用目录（保留官方原始目录）
RUN mkdir -p /app
WORKDIR /home/user/app

# 复制应用文件
COPY --chown=user:user . /home/user/app

# 安装 Python 依赖
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt
RUN mkdir -p /etc/supervisor/conf.d

# 创建日志目录并设置权限
RUN mkdir -p /var/log/supervisor && \
    chown user:user /var/log/supervisor && \
    chmod 755 /var/log/supervisor

# 创建 supervisor 配置（修复日志路径）
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'logfile=/var/log/supervisor/supervisord.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'logfile_maxbytes=0' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'pidfile=/var/run/supervisord.pid' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=user' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:traffmonetizer]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'directory=/app' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=bash -c "/app/Cli start accept --token $TRAFFMONETIZER_TOKEN"' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile=/var/log/supervisor/traffmonetizer.err.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile=/var/log/supervisor/traffmonetizer.out.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'environment=TRAFFMONETIZER_TOKEN="%(ENV_TRAFFMONETIZER_TOKEN)s"' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=user' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:webapp]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=python3 /home/user/app/app.py' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'directory=/home/user/app' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile=/var/log/supervisor/webapp.err.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile=/var/log/supervisor/webapp.out.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'user=user' >> /etc/supervisor/conf.d/supervisord.conf

# 暴露端口 7860
EXPOSE 7860

# 使用 supervisor 启动所有服务
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
