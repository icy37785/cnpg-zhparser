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
        pkg-config \
    && if grep -q "deb-src" /etc/apt/sources.list.d/pgdg.list > /dev/null; then \
        echo "deb [trusted=yes] https://apt.fury.io/abcfy2/ /" >/etc/apt/sources.list.d/fury.list; \
        apt-get update; \
        fi \
    && LIBPQ5_VER="$(dpkg-query --showformat='${Version}' --show libpq5)" \
    && apt-get install -y libpq-dev="${LIBPQ5_VER}" postgresql-server-dev-${PG_MAJOR} \
    && rm -rf /var/lib/apt/lists/*

# 构建 SCWS
WORKDIR /tmp
RUN set -ex &&\
    wget -O scws.tar.bz2 "http://www.xunsearch.com/scws/down/scws-1.2.3.tar.bz2" && \
    tar -xjf scws.tar.bz2 && \
    cd scws-1.2.3 \
    && ./configure \
    && make -j$(nproc) install V=0 && \
    ldconfig

# 构建 zhparser
RUN set -ex &&\
    git clone --depth 1 https://github.com/amutu/zhparser.git && \
    cd zhparser && \
    make -j$(nproc) install 

# 验证构建结果
RUN echo "=== 验证构建结果 ===" && \
    ls -la /usr/lib/postgresql/${PG_MAJOR}/lib/zhparser.so && \
    ls -la /usr/share/postgresql/${PG_MAJOR}/extension/zhparser.control && \
    ldd /usr/lib/postgresql/${PG_MAJOR}/lib/zhparser.so

# 运行时镜像
FROM ghcr.io/cloudnative-pg/postgresql:${PG_MAJOR}-standard-bookworm
ARG PG_MAJOR

LABEL org.opencontainers.image.title="PostgreSQL with zhparser for CloudNative-PG"
LABEL org.opencontainers.image.description="PostgreSQL ${PG_MAJOR} with zhparser extension, compatible with CloudNative-PG"
LABEL org.opencontainers.image.source="https://github.com/icy37785/cnpg-zhparser"
LABEL org.opencontainers.image.licenses="MIT"

USER root

# 设置中文环境
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales && \
    localedef -i zh_CN -c -f UTF-8 -A /usr/share/locale/locale.alias zh_CN.UTF-8 && \
    rm -rf /var/lib/apt/lists/*

ENV LANG=zh_CN.UTF-8

# 安装到正确的 PostgreSQL 版本目录
RUN echo "=== 安装到正确的 PostgreSQL 版本目录 ==="
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/zhparser.so /usr/lib/postgresql/${PG_MAJOR}/lib/
COPY --from=builder /usr/local/lib/libscws.* /usr/local/lib/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/zhparser* /usr/share/postgresql/${PG_MAJOR}/extension/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/zhparser* /usr/lib/postgresql/${PG_MAJOR}/lib/bitcode/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/tsearch_data/*.utf8.* /usr/share/postgresql/${PG_MAJOR}/tsearch_data/

# 更新动态库缓存
RUN ldconfig

# Change the uid of postgres to 26
RUN usermod -u 1000 postgres

# 统一设置权限（在 UID 修改之后）
#RUN chown -R postgres:postgres /usr/lib/postgresql/${PG_MAJOR} && \
#    chown -R postgres:postgres /usr/share/postgresql/${PG_MAJOR} && \
#    chown postgres:postgres /usr/local/lib/libscws.* && \
#    chmod 755 /usr/lib/postgresql/${PG_MAJOR}/lib/zhparser.so

USER 1000

ENV PATH=$PATH:/usr/lib/postgresql/${PG_MAJOR}/bin

# 验证安装
RUN echo "=== 最终验证 ===" && \
    ls -la /usr/lib/postgresql/${PG_MAJOR}/lib/zhparser.so && \
    ls -la /usr/share/postgresql/${PG_MAJOR}/extension/zhparser.control && \
    ldd /usr/lib/postgresql/${PG_MAJOR}/lib/zhparser.so && \
    echo "✅ 安装完成"