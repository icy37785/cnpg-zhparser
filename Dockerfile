# Dockerfile
ARG PG_MAJOR=17
FROM postgres:${PG_MAJOR} AS builder
#FROM debian:bookworm-slim AS builder

# 安装构建依赖
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        bzip2 \
        ca-certificates \
        curl \
        git \
        gcc \
        wget \
        libc6-dev \
        make \
    &&  if grep -q "deb-src" /etc/apt/sources.list.d/pgdg.list > /dev/null; then \
        echo "deb [trusted=yes] https://apt.fury.io/abcfy2/ /" >/etc/apt/sources.list.d/fury.list; \
        apt-get update; \
        fi \
    && LIBPQ5_VER="$(dpkg-query --showformat='${Version}' --show libpq5)" \
    && apt-get install -y libpq-dev="${LIBPQ5_VER}" postgresql-server-dev-$PG_MAJOR

# 构建 SCWS
#WORKDIR /tmp
RUN set -ex &&\
    wget -O scws.tar.bz2 "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" && \
    tar -xjf scws.tar.bz2 && \
    cd scws-1.2.3 \
    && ./configure \
    && make -j$(nproc) install V=0

# 构建 zhparser
RUN set -ex &&\
    git clone --depth 1 https://github.com/amutu/zhparser.git && \
    cd zhparser && \
    make -j$(nproc) install 

# 运行时镜像
FROM ghcr.io/cloudnative-pg/postgresql:${PG_MAJOR}-standard-bookworm
ARG PG_MAJOR

LABEL org.opencontainers.image.title="PostgreSQL with zhparser for CloudNative-PG"
LABEL org.opencontainers.image.description="PostgreSQL ${PG_MAJOR} with zhparser extension, compatible with CloudNative-PG"
LABEL org.opencontainers.image.source="https://github.com/icy37785/cnpg-zhparser"
LABEL org.opencontainers.image.licenses="MIT"

USER root

RUN localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8
ENV LANG=zh_CN.UTF-8

RUN chown -R postgres:postgres /usr/lib/postgresql/${PG_MAJOR} && \
    chmod -R 0700 /usr/lib/postgresql/${PG_MAJOR}
RUN chown postgres "/usr/share/postgresql/${PG_MAJOR}/extension"

# 安装到正确的 PostgreSQL 版本目录
RUN echo "=== 安装到正确的 PostgreSQL 版本目录 ==="
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/zhparser.so /usr/lib/postgresql/${PG_MAJOR}/lib/
COPY --from=builder /usr/local/lib/libscws.* /usr/local/lib/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/zhparser* /usr/share/postgresql/${PG_MAJOR}/extension/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/zhparser* /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/tsearch_data/*.utf8.* /usr/share/postgresql/${PG_MAJOR}/tsearch_data/

# Change the uid of postgres to 26
RUN usermod -u 26 postgres
RUN chown -R postgres:postgres /usr/lib/postgresql/

USER 26

# 使用更简单的健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pg_isready -U postgres || exit 1