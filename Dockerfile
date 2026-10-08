FROM caddy:builder AS builder

RUN xcaddy build \
    --with github.com/lucaslorentz/caddy-docker-proxy/v2 \
    --with github.com/WeidiDeng/caddy-cloudflare-ip \
    --with github.com/tuzzmaniandevil/caddy-dynamic-clientip@v1.0.5 \
    --with github.com/monobilisim/caddy-ip-list@fef199d3564e \
    --with github.com/hslatman/caddy-crowdsec-bouncer/http@v0.14.1 \
    --with github.com/hslatman/caddy-crowdsec-bouncer/appsec@v0.14.1

FROM caddy:latest

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

CMD ["caddy", "docker-proxy"]
