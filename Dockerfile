FROM alpine:3.14 AS base

USER root 

ENV NODE_VERSION 17.6.0

RUN apk add --no-cache dumb-init bash

RUN addgroup -g 1000 node \
  && adduser -u 1000 -G node -s /bin/sh -D node \
  && apk add --no-cache \
  libstdc++ \
  && apk add --no-cache --virtual .build-deps \
  curl \
  && ARCH= && alpineArch="$(apk --print-arch)" \
  && case "${alpineArch##*-}" in \
  x86_64) \
  ARCH='x64' \
  CHECKSUM="b049228a117aa1cd2917aa67703efc8100973f5451e2dc819d0c534570d3e7c7" \
  ;; \
  *) ;; \
  esac \
  && if [ -n "${CHECKSUM}" ]; then \
  set -eu; \
  curl -fsSLO --compressed "https://unofficial-builds.nodejs.org/download/release/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz"; \
  echo "$CHECKSUM  node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs; \
  else \
  echo "Building from source" \
  # backup build
  && apk add --no-cache --virtual .build-deps-full \
  binutils-gold \
  g++ \
  gcc \
  gnupg \
  libgcc \
  linux-headers \
  make \
  python3 \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && for key in \
  4ED778F539E3634C779C87C6D7062848A1AB005C \
  94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
  74F12602B6F1C4E913FAA37AD3A89613643B6201 \
  71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
  8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
  C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
  C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
  DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
  A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
  108F52B48DB57BB0CC439B2997B01419BD92F80A \
  B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
  gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
  gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xf "node-v$NODE_VERSION.tar.xz" \
  && cd "node-v$NODE_VERSION" \
  && ./configure \
  && make -j$(getconf _NPROCESSORS_ONLN) V= \
  && make install \
  && apk del .build-deps-full \
  && cd .. \
  && rm -Rf "node-v$NODE_VERSION" \
  && rm "node-v$NODE_VERSION.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt; \
  fi \
  && rm -f "node-v$NODE_VERSION-linux-$ARCH-musl.tar.xz" \
  && apk del .build-deps \
  # smoke tests
  && node --version \
  && npm --version

ENV YARN_VERSION 1.22.17

RUN apk add --no-cache --virtual .build-deps-yarn curl gnupg tar \
  && for key in \
  6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
  gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys "$key" || \
  gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && apk del .build-deps-yarn \
  # smoke test
  && yarn --version

RUN \
  mkdir /opt/app-root && \
  chown node:node /opt/app-root

RUN \
  touch /opt/app-root/app.log && \
  chown node:node /opt/app-root/app.log && \
  chmod 0750 /opt/app-root/app.log


###################################
# Postgres
###################################
FROM base as dev_postgresql

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


###################################
# Redis - Postgres
###################################
FROM dev_postgresql as dev_redis

COPY entrypoint-*.sh /
RUN find / -type f -name 'entrypoint-*.sh' -exec chown -R 755 {} \;
RUN find / -type f -name 'entrypoint-*.sh' -exec chown -R node:node {} \;
RUN find / -type f -name 'entrypoint-*.sh' -exec chmod +x {} \;

RUN \
  apk --update add redis && \
  rm -rf /var/cache/apk/*

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


###################################
# Postgres Sandbox
###################################
FROM dev_postgresql as sandbox-postgresql

USER node

COPY package*.json ./
COPY node_modules ./node_modules
COPY health-checks ./health-checks
COPY src ./src
EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["bash", "-c", "printenv & sleep 10 & /entrypoint-postgres.sh && /entrypoint-node.sh"]

###################################
# Redis Sandbox
###################################
FROM dev_redis as sandbox_redis

USER node

COPY package*.json ./
COPY node_modules ./node_modules
COPY health-checks ./health-checks
COPY src ./src
EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["bash", "-c", "printenv & sleep 10 & /entrypoint-redis.sh & /entrypoint-postgres.sh & /entrypoint-node.sh"]

###################################
# Postgres Sandbox
###################################
FROM dev_redis as sandbox_bash

USER node

COPY package*.json ./
COPY node_modules ./node_modules
COPY health-checks ./health-checks
COPY src ./src
EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["bash"]

###################################
# Node Sandbox
###################################
FROM base as sandbox_nodejs

USER node

WORKDIR /opt/app-root
COPY package*.json ./
COPY node_modules ./node_modules
COPY src ./src
EXPOSE 3000

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

CMD ["bash", "-c", "printenv & sleep 10 && /entrypoint-node.sh"]
