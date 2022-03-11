FROM carlosmarte/alpine3_14_nodejs17_6_base AS builder

FROM builder

ENV LANG en_US.utf8
ENV PGPORT 5432
ENV POSTGRES_HOST_AUTH_METHOD trust
ENV PGUSER postgres:-postgres
ENV PGDATA /pgdata

WORKDIR /opt/app-root

COPY entrypoint-*.sh /
RUN find / -type f -name 'entrypoint-*.sh' -exec chown -R 755 {} \;
RUN find / -type f -name 'entrypoint-*.sh' -exec chown -R node:node {} \;
RUN find / -type f -name 'entrypoint-*.sh' -exec chmod +x {} \;

RUN \
    apk --update add postgresql && \
    rm -rf /var/cache/apk/*

RUN set -eux; \
    chown -R node:postgres /var/lib/postgresql

RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 0750 "$PGDATA"

RUN \
    touch /opt/app-root/app.log && \
    chown node:node /opt/app-root/app.log && \
    chmod 0750 /opt/app-root/app.log

RUN \
    mkdir -p /var/log/postgresql && \
    mkdir -p /run/postgresql && \
    chown postgres:postgres /run/postgresql -R && \
    chmod g+rwx /run/postgresql -R  && \
    chown "1000:1000" /run -R

VOLUME ["/run/postgresql", "/var/lib/postgresql/data"]

USER postgres
RUN initdb --username=postgres --auth=trust --auth-local=trust --pgdata="$PGDATA"
RUN sed -i 's#unix_socket_directories#\#unix_socket_directories#i' "$PGDATA/postgresql.conf"
RUN echo -e "host all all all trust\n" >> "$PGDATA/pg_hba.conf"
RUN echo -e "listen_addresses = '*'\n" >> "$PGDATA/postgresql.conf"
RUN echo -e "log_directory = 'log'\n" >> "$PGDATA/postgresql.conf"
RUN echo -e "log_file_mode = 0600\n" >> "$PGDATA/postgresql.conf"
RUN echo -e "log_destination = 'stderr'\n" >> "$PGDATA/postgresql.conf"
RUN echo -e "port=5432\n" >> "$PGDATA/postgresql.conf"
RUN echo -e "unix_socket_directories = '/run/postgresql,/tmp'\n" >> "$PGDATA/postgresql.conf"

USER root
RUN chown -R "1000:1000" "$PGDATA" && chmod 0750 "$PGDATA"
RUN chown -R "1000:1000" "/var/lib/postgresql" && chmod 0750 "/var/lib/postgresql"
RUN chown -R "1000:1000" "/var/log/postgresql" && chmod 0750 "/var/log/postgresql"
# RUN chown -R postgres:postgres /var/run/postgresql

USER node

COPY package*.json ./
COPY node_modules ./node_modules
COPY health-checks ./health-checks
COPY src ./src
EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["bash", "-c", "printenv & sleep 10 & /entrypoint-postgres.sh && /entrypoint-node.sh"]
# CMD ["bash"]