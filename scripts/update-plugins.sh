#!/bin/bash
#
# update-plugins.sh — bump every PINNED plugin in the Dockerfile to its latest upstream version.
#
# A pinned plugin is an xcaddy line `--with <package>@<version>`. Unpinned lines are left alone.
#   - pinned to a tag (`@v1.2.3`): moves to the latest tagged release;
#   - pinned to a commit (`@<hex>`, for repos without tags): moves to the latest commit of the
#     default branch, or to a tag once the repo starts tagging.
# Versions come from the Go module proxy (proxy.golang.org), the same source xcaddy builds from.
#
# Edits the Dockerfile in place and prints one line per change. Prints nothing and changes
# nothing when everything is current. Run by .github/workflows/update-plugins.yml, which opens a
# pull request with the result; it can also be run by hand.
#
# Usage: scripts/update-plugins.sh [Dockerfile]
set -euo pipefail

DOCKERFILE="${1:-Dockerfile}"
PROXY="${GOPROXY_URL:-https://proxy.golang.org}"

# The proxy wants upper-case letters escaped as `!` + lower case (golang.org/ref/mod#goproxy-protocol).
escape() { printf '%s' "$1" | sed 's/[A-Z]/!\L&/g'; }

# latest_info <package> — the proxy's @latest JSON for the module that contains <package>. A
# package such as `.../caddy-crowdsec-bouncer/http` lives in the module one level up, so walk up
# until the proxy knows the path.
latest_info() {
    local path="$1" out
    while [[ "$path" == */*/* ]]; do
        if out="$(curl -fsS --max-time 30 "$PROXY/$(escape "$path")/@latest" 2>/dev/null)"; then
            printf '%s' "$out"
            return 0
        fi
        path="${path%/*}"
    done
    return 1
}

is_pseudo() { [[ "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-([0-9]+\.)?[0-9]{14}-[0-9a-f]{12}$ ]]; }

while read -r pkg pinned; do
    if ! info="$(latest_info "$pkg")"; then
        echo "ERROR: $pkg: not found on $PROXY" >&2
        exit 1
    fi
    version="$(jq -r .Version <<<"$info")"
    if is_pseudo "$version"; then
        new="${version##*-}"            # no tags upstream: pin the 12-char commit
    else
        new="$version"
    fi
    if [ "$new" != "$pinned" ]; then
        sed -i "s#--with ${pkg}@${pinned}\\b#--with ${pkg}@${new}#" "$DOCKERFILE"
        echo "$pkg: $pinned -> $new ($(jq -r .Time <<<"$info"))"
    fi
done < <(sed -n 's#.*--with \([^ @]*\)@\([^ \\]*\).*#\1 \2#p' "$DOCKERFILE")

exit 0
