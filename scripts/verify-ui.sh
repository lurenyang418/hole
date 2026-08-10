#!/usr/bin/env bash
set -euo pipefail

IMAGE=${1:?usage: verify-ui.sh IMAGE}

docker run --rm --entrypoint /bin/sh "${IMAGE}" -ec '
  test -f /usr/share/mihomo/ui/index.html
  test -n "$(find /usr/share/mihomo/ui -type f | head -1)"
  test "$(printf "%s" "${SAFE_PATHS:-}" | tr ":" "\n" | grep -Fx /usr/share/mihomo/ui)" = /usr/share/mihomo/ui
'
