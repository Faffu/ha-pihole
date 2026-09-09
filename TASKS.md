# Implementation Plan

## Phase 0 — Research / decisions

- [x] Verify current stable Pi-hole v6 Docker release.
- [x] Verify whether the upstream Pi-hole image can be safely used as the App base.
- [ ] Verify HAOS port 53 mapping behavior on a clean test host.
- [x] Verify Pi-hole web UI behavior through Home Assistant Ingress.
- [x] Decide persistent storage mapping.
- [x] Decide exact App config schema.
- [ ] Review blocklist licenses.

## Phase 1 — Minimal working App

- [x] `repository.yaml`
- [x] `pihole/config.yaml`
- [x] pinned Dockerfile
- [x] startup script
- [x] persistent `/etc/pihole`
- [x] port 53 TCP/UDP
- [x] upstream DNS options
- [x] timezone option
- [x] secure web password handling
- [x] no DHCP / no UDP 67 / no NET_ADMIN
- [x] basic logs
- [x] amd64 build
- [x] aarch64 build

## Phase 2 — Web UI

- [x] Test direct Web UI.
- [ ] Test HA Ingress.
- [x] Implement Ingress only if reliable.
- [ ] Add sidebar presentation if Ingress is reliable.
- [x] Add watchdog/healthcheck.

## Phase 3 — Blocklist manager

- [x] Balanced preset: HaGeZi Pro.
- [x] Security preset.
- [x] Strict preset.
- [x] custom list option.
- [x] idempotent App-managed list tracking.
- [x] preserve user-managed lists.
- [x] Gravity refresh on meaningful changes only.
- [x] false-positive docs.

## Phase 4 — Backup / restore

- [x] Verify persistent state coverage.
- [x] Determine hot vs cold backup.
- [ ] Test restore.
- [x] document restore behavior.

## Phase 5 — CI/CD

- [x] YAML lint.
- [x] ShellCheck.
- [x] App config validation.
- [x] multi-arch builds.
- [x] GHCR push.
- [x] release tags.
- [x] version consistency validation.
- [ ] changelog release automation.

## Phase 6 — HAOS validation

Not started. Nothing in this phase has been run on real Home Assistant OS
hardware. Local container smoke tests are not a substitute.

Test on real HAOS:

- [ ] clean install
- [ ] start/stop/restart
- [ ] reboot
- [ ] DNS UDP
- [ ] DNS TCP
- [ ] upstream resolution
- [ ] blocking
- [ ] Pi-hole UI
- [ ] App config changes
- [ ] profile changes
- [ ] custom blocklists
- [ ] backup
- [ ] restore
- [ ] upgrade
- [ ] logs contain no password
- [ ] UDP 67 closed
- [ ] no DHCP service
- [ ] no unnecessary capabilities

## Phase 7 — Documentation / release

- [x] README
- [x] DOCS
- [x] English translations
- [x] Italian translations
- [x] troubleshooting
- [x] router DNS setup guidance
- [x] IPv6 guidance
- [x] recovery if DNS fails
- [ ] first stable release
