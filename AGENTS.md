# omitsis-devops/caddy

Image `ghcr.io/omitsis-devops/caddy`: the official `caddy` image plus the plugins sistemes-stack
needs (`Dockerfile`, list in `README.md`). It is the Caddy every Omitsis server runs; servers pull
`:latest` on their own.

GitHub Actions (`.github/workflows/docker-image.yml`) builds and publishes `:latest` on every push
to `main`, every Monday at 03:00 UTC (to pick up upstream `caddy` releases) and on manual runs.
There is no path filter, so even a docs-only push rebuilds and republishes. A push to `main`
ships to every server. Don't push without the user's go-ahead.

## Plugins

The plugins are pinned in the `Dockerfile` (except `caddy-docker-proxy` and
`caddy-cloudflare-ip`). `.github/workflows/update-plugins.yml` opens a monthly pull request
bumping them; it must be built and run on a test server before merging (README, "Build").

## Rule: removing or renaming a plugin

sistemes-stack (`services/caddy/compose.yml`: the `omitsis_edge` snippet, its CrowdSec bouncer,
ADR-011, ADR-014) depends on these plugins: `docker-proxy`, `trusted_proxies cloudflare`,
`dynamic_client_ip` + `list`, `crowdsec`. Removing or renaming one, or taking a breaking change in
one, breaks Caddy on every server: remind the user that sistemes-stack must be updated first.
