#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMAGE=${1:?usage: smoke-test.sh IMAGE}
NAME="mihomo-smoke-${RANDOM}-${RANDOM}"
TMP_DIR=$(mktemp -d)

cleanup() {
  docker rm -f "${NAME}" >/dev/null 2>&1 || true
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

mkdir -p "${TMP_DIR}/config"
cp -a "${ROOT_DIR}/examples/mihomo/." "${TMP_DIR}/config/"

docker run -d --name "${NAME}" \
  -p 127.0.0.1::7890 \
  -p 127.0.0.1::9090 \
  -v "${TMP_DIR}/config:/root/.config/mihomo" \
  "${IMAGE}" >/dev/null

controller_port=$(docker port "${NAME}" 9090/tcp | sed -E 's/.*://')
secret=CHANGE_ME_TO_A_LONG_RANDOM_SECRET

ready=0
for _ in $(seq 1 30); do
  if env NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost \
    curl --fail --silent "http://127.0.0.1:${controller_port}/ui/" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

test "${ready}" = 1
env NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost \
  curl --fail --silent --show-error "http://127.0.0.1:${controller_port}/ui/" | grep -qi '<html'
env NO_PROXY=127.0.0.1,localhost no_proxy=127.0.0.1,localhost \
  curl --fail --silent --show-error \
  -H "Authorization: Bearer ${secret}" \
  "http://127.0.0.1:${controller_port}/version" | grep -q '"version"'

docker inspect -f '{{.State.Running}}' "${NAME}" | grep -q true
docker inspect -f '{{range .Config.Env}}{{println .}}{{end}}' "${NAME}" | grep -qx 'SAFE_PATHS=/usr/share/mihomo/ui'
