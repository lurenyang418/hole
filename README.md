# Mihomo NAS Docker Distribution

A minimal NAS/server-oriented Mihomo image with the official MetaCubeXD static
dashboard bundled into the image. The project packages upstream software; it
does not fork Mihomo or build a separate proxy core.

## Architecture

```text
application containers -> mihomo:7890 -> Mihomo rules
browser               -> 127.0.0.1:9090/ui/
optional dockerd      -> 127.0.0.1:7890 -> Mihomo
```

The image contains one runtime process: Mihomo. There is no Caddy, nginx,
Node.js runtime, supervisor, TUN setup, or host-network requirement.

## Quick start

Edit `examples/mihomo/config.yaml` and replace the placeholder `secret` with a
long random value. Add your proxy providers, proxies, groups, and rules to
that directory. The Compose examples mount the complete `mihomo` directory so
provider data and Mihomo state survive container replacement.

The Compose examples default to the published image. Start the container-only
example with:

```bash
docker compose -f examples/compose.yaml up -d
```

To pin a specific release or use a locally built image, override the image:

```bash
MIHOMO_IMAGE=ghcr.io/lurenyang418/hole:0.1.0 \
  docker compose -f examples/compose.yaml up -d
```

Open `http://127.0.0.1:9090/ui/`. The controller is intentionally published
only on host loopback in the recommended example. For a NAS reverse proxy,
forward HTTPS traffic to host port `9090` and retain the `/ui/` path.

Port `7890` is not published to the LAN. Containers joined to the
`mihomo-proxy` network use `http://mihomo:7890`.

## Proxy another container

Run the Mihomo Compose example first so the external network exists, then set
the client image and start the template:

```bash
export APP_IMAGE=your.registry.example/app:tag
docker compose -f examples/app-with-proxy.yaml up -d
```

The application must support standard `HTTP_PROXY`/`HTTPS_PROXY` environment
variables. Those variables send the request to Mihomo; Mihomo's own rules
still decide whether the destination is `DIRECT` or uses a proxy node.

## Optional host-proxy mode

Use `examples/compose.host-proxy.yaml` when the NAS host or Docker daemon must
use Mihomo. It publishes both ports on `127.0.0.1` only:

```bash
docker compose -f examples/compose.host-proxy.yaml up -d
```

This mode does not automatically configure the Docker daemon. For Docker
Engine 23.0+, adapt `examples/docker-daemon-proxy.json.example` into the
daemon's configuration. The usual Linux path is `/etc/docker/daemon.json`;
restart the daemon using the platform's supported mechanism.

Rootless Docker, Docker Desktop, and NAS products whose daemon runs in a
separate VM or network namespace may not be able to reach a host-published
`127.0.0.1` port. Follow the platform-specific persistent proxy mechanism in
that case. `~/.docker/config.json` controls client/build/container proxy
injection and is not a replacement for the daemon proxy.

## First-pull dependency

If Docker itself will use Mihomo as its proxy, the Mihomo image must first be
pulled or imported through an already working network path. Only after the
container is local can the daemon proxy be pointed at `127.0.0.1:7890`.

Registry mirrors can reduce repeated Docker Hub downloads, but they are an
optional cache and do not replace proxy connectivity to GHCR, Quay, or other
registries.

## Security defaults

- TUN is disabled.
- No `privileged`, `NET_ADMIN`, host networking, or host route changes are used.
- The controller requires the configured Mihomo `secret`.
- Recommended examples do not expose `7890` to the LAN or Internet.
- Do not expose the controller directly to the public Internet.

This is explicit application proxying, not transparent proxy routing. TUN,
TPROXY, REDIR, iptables, and automatic host mutation are outside v0.1.0.

## Upstream versions

Pinned inputs are recorded in [`versions.env`](versions.env):

- Mihomo `v1.19.29`
- MetaCubeXD `v1.270.6`

The MetaCubeXD asset is downloaded from the official release and verified by
SHA-256 during the image build. The base image and Alpine build image are
locked by multi-architecture manifest digest.

See the upstream [Mihomo documentation](https://wiki.metacubex.one/en/) for
advanced configuration, rules, and protocols, and the
[MetaCubeXD project](https://github.com/MetaCubeX/metacubexd) for dashboard
details.

## License

The packaging files in this repository are MIT-licensed. The image redistributes
Mihomo under GPL-3.0 and MetaCubeXD under MIT, in addition to the licenses of
the official Alpine base image and its packages. See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

## Dependency updates

Dependabot checks GitHub Actions dependencies weekly. A separate workflow
enables squash auto-merge for Dependabot pull requests only after the CI
workflow succeeds. Mihomo and Alpine image version/digest pins are kept
together in `versions.env`; update those inputs as a unit so reproducible builds
do not end up with a changed tag and a stale digest.
