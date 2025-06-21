# 基于 traffmonetizer 官方镜像
FROM traffmonetizer/cli_v2:latest
ENTRYPOINT []

# 设置用户权限 (Hugging Face Spaces 要求)
USER root
RUN apk update && apk add --no-cache shadow python3 py3-pip supervisor && rm -rf /var/cache/apk/*
RUN useradd -m -u 1000 user

# 创建应用目录
RUN mkdir -p /home/user/app
WORKDIR /home/user/app

# 复制应用文件
COPY --chown=user:user . /home/user/app

# 安装 Python 依赖
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt
# Ensure the supervisor config directory exists
RUN mkdir -p /etc/supervisor/conf.d
# 创建 supervisor 配置
RUN echo '[supervisord]' > /etc/supervisor/conf.d/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:traffmonetizer]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=/usr/local/bin/traffmonetizer start accept --token %(ENV_TRAFFMONETIZER_TOKEN)s' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile=/var/log/traffmonetizer.err.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile=/var/log/traffmonetizer.out.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo '[program:webapp]' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'command=python3 /home/user/app/app.py' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'directory=/home/user/app' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'autorestart=true' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stderr_logfile=/var/log/webapp.err.log' >> /etc/supervisor/conf.d/supervisord.conf && \
    echo 'stdout_logfile=/var/log/webapp.out.log' >> /etc/supervisor/conf.d/supervisord.conf

# 暴露端口 7860 (Hugging Face Spaces 默认端口)
EXPOSE 7860

# 使用 supervisor 启动所有服务
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

