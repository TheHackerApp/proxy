ARG OPENRESTY_VERSION=1.25.3.1
FROM openresty/openresty:${OPENRESTY_VERSION}-alpine as base

# Build OpenTelemetry Lua module
FROM openresty/openresty:${OPENRESTY_VERSION}-alpine-fat as opentelemetry-lua

ARG OPENTELEMETRY_LUA_VERSION=6e44fe8352a032f8a24fffef3c0a43a05ee49e33

RUN apk add --no-cache git

# Fetch and build OpenTelemetry Lua module
RUN set -e && \
    git clone https://github.com/yangxikun/opentelemetry-lua.git && \
    cd opentelemetry-lua && \
    git checkout ${OPENTELEMETRY_LUA_VERSION} && \
    luarocks make

# Build OpenTelemetry Nginx module
FROM base as opentelemetry

ARG JOBS=4
ARG OPENTELEMETRY_CPP_VERSION=v1.12.0
ARG OPENTELEMETRY_NGINX_VERSION=v1.0.4

# Install system dependencies
RUN apk add --no-cache \
    abseil-cpp-dev \
    autoconf \
    automake \
    benchmark-dev \
    build-base \
    cmake \
    curl \
    curl-dev \
    git \
    grpc-dev \
    gtest-dev \
    g++ \
    libtool \
    pcre2-dev \
    pkgconf \
    protobuf-dev \
    unzip \
    zlib-dev

COPY hack /hack

# Build & install OpenTelemetry C++ SDK
RUN set -x && \
    source /hack/clean-otel-env-vars.sh && \
    git clone --recurse-submodules -b ${OPENTELEMETRY_CPP_VERSION} https://github.com/open-telemetry/opentelemetry-cpp.git && \
    cd opentelemetry-cpp && \
    git apply /hack/patches/opentelemetry-cpp/*.patch && \
    mkdir build && \
    cd build && \
    cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DWITH_OTLP_GRPC=ON \
    -DWITH_OTLP_HTTP=OFF \
    -DWITH_ABSEIL=ON \
    && \
    cmake --build . --target all -j ${JOBS} && \
    ctest -j ${JOBS} --output-on-failure && \
    cmake --install . && \
    cd / && \
    rm -rf opentelemetry-cpp

# Build OpenTelemetry Nginx module
RUN set -x && \
    git clone -b webserver/${OPENTELEMETRY_NGINX_VERSION} https://github.com/open-telemetry/opentelemetry-cpp-contrib.git && \
    cd opentelemetry-cpp-contrib/instrumentation/nginx && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local/lib && \
    make -j ${JOBS} && \
    make install && \
    cd / && \
    rm -rf opentelemetry-cpp-contrib

FROM base as develop

# Copy over OpenTelemetry Nginx and Lua modules and their runtime dependencies
RUN apk add --no-cache abseil-cpp grpc grpc-cpp pcre2 protobuf zlib perl
COPY --from=opentelemetry-lua /usr/local/openresty/luajit/share/lua/5.1/ /usr/local/openresty/luajit/share/lua/5.1/
COPY --from=opentelemetry-lua /usr/local/openresty/luajit/lib/lua/5.1/ /usr/local/openresty/luajit/lib/lua/5.1/
COPY --from=opentelemetry /usr/local/lib/* /usr/local/lib/

# For envsubst, we install gettext (envsubst's source package),
# copy it out, then uninstall gettext (to save some space as envsubst is very small)
# libintl and musl are dependencies of envsubst, so those are installed as well
RUN set -x \
    && apk add --no-cache libintl musl \
    && apk add --no-cache --virtual .gettext gettext \
    && mv /usr/bin/envsubst /tmp/ \
    && apk del .gettext \
    && mv /tmp/envsubst /usr/local/bin/

# Run nginx as non-root user
RUN set -x \
    && addgroup -g 101 -S nginx \
    && adduser -S -D -H -u 101 -h /var/cache/nginx -s /sbin/nologin -G nginx -g nginx nginx

# Get Cloudflare edge IP ranges and whitelist them for Real IP module
COPY --chmod=755 cloudflare-ips.sh /etc/periodic/daily/cloudflare-ips
RUN GENERATE_ONLY=1 /etc/periodic/daily/cloudflare-ips

COPY --chmod=755 ./docker-entrypoint.sh /
COPY --chmod=755 ./docker-entrypoint.d/* /docker-entrypoint.d/
ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD ["openresty", "-g", "daemon off;"]

# Bake in the configuration files into the image
FROM develop as production

# Default environment variables
ENV API_DOMAIN api.thehacker.app
ENV NGINX_AUTOTUNE_WORKER_PROCESSES=1

COPY ./nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY ./opentelemetry.toml /usr/local/openresty/nginx/conf/opentelemetry.toml

COPY ./conf /etc/nginx/conf.d
COPY ./lua /usr/local/openresty/nginx/lua
COPY ./snippets /usr/local/openresty/nginx/conf/snippets.d
COPY ./templates /usr/local/openresty/nginx/templates
