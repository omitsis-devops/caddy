# Omitsis Caddy Docker Image

A prebuilt Caddy image with the plugins Omitsis's `sistemes-stack` needs, so servers pull a
ready binary instead of compiling one with `xcaddy` on every deploy.

It uses the official `caddy` image as its base and adds:

- **[caddy-docker-proxy/v2](https://github.com/lucaslorentz/caddy-docker-proxy)** — configures
  Caddy from Docker labels instead of a static Caddyfile.
- **[caddy-cloudflare-ip](https://github.com/WeidiDeng/caddy-cloudflare-ip)** — resolves
  Cloudflare's IP ranges for `trusted_proxies`, so `X-Forwarded-For` from Cloudflare is trusted.
- **[caddy-dynamic-clientip](https://github.com/tuzzmaniandevil/caddy-dynamic-clientip)** — the
  `dynamic_client_ip` request matcher: like `client_ip`, but its ranges come from an IP source.
- **[caddy-ip-list](https://github.com/monobilisim/caddy-ip-list)** — the `list` IP source: fetches
  CIDR lists (one per line) from URLs on an interval, with a persistent on-disk cache.
- **[caddy-crowdsec-bouncer](https://github.com/hslatman/caddy-crowdsec-bouncer)** (`/http`,
  `/appsec`) — CrowdSec bouncer and AppSec handlers. Inert until a `crowdsec` block is configured.

`sistemes-stack` uses `dynamic_client_ip` + `list` to set the verified-crawler header
(`X-Omitsis-Verified-Bot`) from a list of official crawler IP ranges, and the CrowdSec bouncer
(`crowdsec @not_verified_bot` in its `omitsis_edge` snippet) against the CrowdSec agent it runs on
every host, in simulation mode by default.

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
(Mondays 3 AM) to pick up upstream `caddy` releases even without a commit here.
Built for `linux/amd64` and `linux/arm64/v8`.

**A push to `main` reaches every server.** It publishes `:latest`, which servers pull on their
own. Test changes on a branch first (pushes to other branches build nothing), build the image on
a test server, and merge only then.

**Plugin versions.** The plugins added for the verified-crawler header and CrowdSec are pinned
(`@<tag>`, or `@<commit>` for `caddy-ip-list`, which has no tags), so the weekly rebuild does not
silently pick up their changes. `caddy-docker-proxy` and `caddy-cloudflare-ip` are not pinned
yet.

**Keeping them updated.** `.github/workflows/update-plugins.yml` runs on the 1st of each month
(or by hand from the Actions tab). It runs `scripts/update-plugins.sh`, which asks the Go module
proxy for each pinned plugin's latest version, and opens a pull request from a
`plugin-updates/<date>` branch when something is newer. It skips the run while such a pull
request is still open. It builds and publishes nothing: test the pull request's branch on a test
server, then merge. To bump by hand, run `scripts/update-plugins.sh` (needs `curl` and `jq`) or
edit the version in the `Dockerfile`.

For the workflow to open pull requests, the repository (or the organisation) must allow it:
*Settings → Actions → General → Workflow permissions → "Allow GitHub Actions to create and
approve pull requests"*.

```sh
docker build -t caddy .
```
