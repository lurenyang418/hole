#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE=${1:?usage: validate-config.sh IMAGE}

docker run --rm \
  --entrypoint /mihomo \
  -v "${ROOT_DIR}/examples/mihomo:/root/.config/mihomo:ro" \
  "${IMAGE}" \
  -t -d /root/.config/mihomo
