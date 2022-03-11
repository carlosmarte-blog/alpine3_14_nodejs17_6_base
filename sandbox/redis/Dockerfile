FROM carlosmarte/alpine3_14_nodejs17_6_base AS builder

FROM builder

WORKDIR /opt/app-root

COPY entrypoint-*.sh /
RUN find / -type f -name 'entrypoint-*.sh' -exec chown -R 755 {} \;
RUN find / -type f -name 'entrypoint-*.sh' -exec chown -R node:node {} \;
RUN find / -type f -name 'entrypoint-*.sh' -exec chmod +x {} \;

RUN \
    apk --update add redis && \
    rm -rf /var/cache/apk/*

RUN \
    touch /opt/app-root/app.log && \
    chown node:node /opt/app-root/app.log && \
    chmod 0750 /opt/app-root/app.log

RUN \
    mkdir /data-redis && \
    mkdir -p /var/log/redis && \
    chown -R redis:redis /data-redis && \
    sed -i 's#logfile /var/log/redis/redis.log#logfile ""#i' /etc/redis.conf && \
    # sed -i 's#daemonize yes#daemonize no#i' /etc/redis.conf && \
    sed -i 's#dir /var/lib/redis#dir /data-redis#i' /etc/redis.conf && \
    echo -e "# placeholder for local options\n" /ect/redis-local.conf && \
    echo -e "include /etc/redis-local.conf" >> /etc/redis.conf


VOLUME ["/data-redis"]

USER node

COPY package*.json ./
COPY node_modules ./node_modules
COPY health-checks ./health-checks
COPY src ./src
EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["bash", "-c", "printenv & sleep 10 & /entrypoint-redis.sh && /entrypoint-node.sh"]
# CMD ["bash"]