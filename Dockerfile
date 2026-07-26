# syntax=docker/dockerfile:1
FROM alpine:3.22 AS build

RUN apk add --no-cache build-base linux-headers openssl-dev pcre2-dev zlib-dev

COPY . /src
WORKDIR /src

RUN auto/configure \
        --prefix=/var/lib/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --pid-path=/run/nginx.pid \
        --with-http_ssl_module \
        --with-http_v2_module \
    && make -j"$(nproc)"


FROM alpine:3.22

RUN apk add --no-cache openssl pcre2 zlib

# nginx opens the compiled-in default error log before it reads the config,
# and creates its temp dirs under the prefix, so the prefix must exist.
RUN mkdir -p /var/lib/nginx/logs

COPY --from=build /src/objs/nginx /usr/sbin/nginx

# Baked in as the default; docker-compose.yml mounts the same file over it, so
# there is one config to edit either way.
COPY docker/nginx.conf /etc/nginx/nginx.conf

EXPOSE 67
CMD ["nginx"]
