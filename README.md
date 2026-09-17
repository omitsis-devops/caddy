# Omitsis Caddy Docker Image

A prebuilt Caddy image with the plugins Omitsis's `sistemes-stack` needs, so servers pull a
ready binary instead of compiling one with `xcaddy` on every deploy.

It uses the official `caddy` image as its base and adds:

- **[caddy-docker-proxy/v2](https://github.com/lucaslorentz/caddy-docker-proxy)** — configures
  Caddy from Docker labels instead of a static Caddyfile.
- **[caddy-cloudflare-ip](https://github.com/WeidiDeng/caddy-cloudflare-ip)** — resolves
  Cloudflare's IP ranges for `trusted_proxies`, so `X-Forwarded-For` from Cloudflare is trusted.

## Image

```
ghcr.io/omitsis-devops/caddy:latest
ghcr.io/omitsis-devops/caddy:<YYYYMMDD>-<short-sha>
```

`:latest` always points at the most recent build. The dated/sha tag is there so a specific
build can be pinned or rolled back to if needed.

## Usage

```yaml
services:
  caddy:
    image: ghcr.io/omitsis-devops/caddy:latest
    pull_policy: always
    command: ["caddy", "docker-proxy"]
```

## Build

The GitHub Action rebuilds and pushes on every push to `main`, and on a weekly schedule
(Mondays 3 AM) to pick up upstream `caddy`/plugin releases even without a commit here.
Built for `linux/amd64` and `linux/arm64/v8`.

```sh
docker build -t caddy .
```
