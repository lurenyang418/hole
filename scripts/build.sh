#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
# versions.env is intentionally a simple KEY=value file maintained with the
# repository. Do not source files from untrusted working trees.
# shellcheck disable=SC1091
source "${ROOT_DIR}/versions.env"

: "${MIHOMO_VERSION:?MIHOMO_VERSION is required}"
: "${MIHOMO_IMAGE_DIGEST:?MIHOMO_IMAGE_DIGEST is required}"
: "${METACUBEXD_VERSION:?METACUBEXD_VERSION is required}"
: "${METACUBEXD_SHA256:?METACUBEXD_SHA256 is required}"
: "${ALPINE_IMAGE_DIGEST:?ALPINE_IMAGE_DIGEST is required}"

IMAGE=${IMAGE:-ghcr.io/OWNER/PROJECT:dev}
TAGS=${TAGS:-${IMAGE}}
PLATFORMS=${PLATFORMS:-linux/amd64}
PROJECT_VERSION=${PROJECT_VERSION:-0.1.0-dev}
VCS_REF=${VCS_REF:-$(git -C "${ROOT_DIR}" rev-parse HEAD 2>/dev/null || printf '%s' unknown)}
BUILD_DATE=${BUILD_DATE:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}
SOURCE_URL=${SOURCE_URL:-https://github.com/OWNER/PROJECT}
PUSH=${PUSH:-0}

build_args=(
  --build-arg "MIHOMO_VERSION=${MIHOMO_VERSION}"
  --build-arg "MIHOMO_IMAGE_DIGEST=${MIHOMO_IMAGE_DIGEST}"
  --build-arg "METACUBEXD_VERSION=${METACUBEXD_VERSION}"
  --build-arg "METACUBEXD_SHA256=${METACUBEXD_SHA256}"
  --build-arg "ALPINE_IMAGE_DIGEST=${ALPINE_IMAGE_DIGEST}"
  --build-arg "PROJECT_VERSION=${PROJECT_VERSION}"
  --build-arg "VCS_REF=${VCS_REF}"
  --build-arg "BUILD_DATE=${BUILD_DATE}"
  --build-arg "SOURCE_URL=${SOURCE_URL}"
)

tag_args=()
while IFS= read -r tag; do
  [[ -n "${tag}" ]] && tag_args+=(--tag "${tag}")
done < <(printf '%s\n' "${TAGS}" | tr ',' '\n')

output_args=()
if [[ "${PUSH}" == "1" ]]; then
  output_args+=(--push)
elif [[ "${PLATFORMS}" == *,* ]]; then
  mkdir -p "${ROOT_DIR}/dist"
  output_args+=(--output "type=oci,dest=${ROOT_DIR}/dist/mihomo-nas.oci.tar")
else
  output_args+=(--load)
fi

exec docker buildx build \
  --file "${ROOT_DIR}/Dockerfile" \
  --platform "${PLATFORMS}" \
  "${tag_args[@]}" \
  "${build_args[@]}" \
  "${output_args[@]}" \
  "${ROOT_DIR}"
