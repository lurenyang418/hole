# syntax=docker/dockerfile:1
# check=skip=InvalidDefaultArgInFrom
# The upstream versions and digests are supplied by versions.env/build.sh.
# An empty default would trigger a parser warning before build args arrive.

ARG MIHOMO_VERSION
ARG MIHOMO_IMAGE_DIGEST
ARG METACUBEXD_VERSION
ARG METACUBEXD_SHA256
ARG ALPINE_IMAGE_DIGEST

FROM alpine:3.22@${ALPINE_IMAGE_DIGEST} AS ui

ARG METACUBEXD_VERSION
ARG METACUBEXD_SHA256

RUN apk add --no-cache curl tar

WORKDIR /tmp/ui

RUN curl --fail --location --retry 3 \
      "https://github.com/MetaCubeX/metacubexd/releases/download/${METACUBEXD_VERSION}/compressed-dist.tgz" \
      -o /tmp/ui.tgz \
 && echo "${METACUBEXD_SHA256}  /tmp/ui.tgz" | sha256sum -c - \
 && mkdir /tmp/ui/extracted \
 && tar -xzf /tmp/ui.tgz -C /tmp/ui/extracted \
 && if [ -f /tmp/ui/extracted/index.html ]; then :; \
    elif [ -f /tmp/ui/extracted/dist/index.html ]; then \
      cp -a /tmp/ui/extracted/dist/. /tmp/ui/extracted/; \
    else \
      echo 'MetaCubeXD archive does not contain index.html at a supported layout' >&2; exit 1; \
    fi \
 && test -f /tmp/ui/extracted/index.html

FROM docker.io/metacubex/mihomo:${MIHOMO_VERSION}@${MIHOMO_IMAGE_DIGEST}

COPY --from=ui /tmp/ui/extracted/ /usr/share/mihomo/ui/

# Mihomo requires paths outside its working directory to be explicitly safe.
ENV SAFE_PATHS=/usr/share/mihomo/ui

ARG MIHOMO_VERSION
ARG PROJECT_VERSION=0.1.0-dev
ARG VCS_REF=unknown
ARG BUILD_DATE=unknown
ARG SOURCE_URL=https://github.com/OWNER/PROJECT
ARG METACUBEXD_VERSION

LABEL org.opencontainers.image.title="Mihomo NAS Docker Distribution" \
      org.opencontainers.image.description="NAS/server-oriented Mihomo image with bundled MetaCubeXD" \
      org.opencontainers.image.source="${SOURCE_URL}" \
      org.opencontainers.image.url="${SOURCE_URL}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.version="${PROJECT_VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.licenses="GPL-3.0-only, MIT" \
      io.example.mihomo.version="${MIHOMO_VERSION}" \
      io.example.metacubexd.version="${METACUBEXD_VERSION}"
