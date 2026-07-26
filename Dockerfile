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

# ponytail: config inline, it is four directives; split it out if it grows
COPY <<'EOF' /etc/nginx/nginx.conf
daemon off;
error_log /dev/stderr info;
events { }
http {
    access_log /dev/stdout;
    server {
        listen 67;
        location / { return 200 "Ok\n"; }
    }
}
EOF

EXPOSE 67
CMD ["nginx"]
