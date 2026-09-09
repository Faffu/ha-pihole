# Implementation Plan

## Phase 0 — Research / decisions

- [x] Verify current stable Pi-hole v6 Docker release.
- [x] Verify whether the upstream Pi-hole image can be safely used as the App base.
- [x] Verify HAOS port 53 mapping behavior on a clean test host.
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
- [x] Test HA Ingress.
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
- [x] Test restore.
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

Run on Home Assistant OS 18.2, generic-x86-64, Supervisor add-on installed from
the published repository and GHCR image. Only the host reboot is outstanding.

Test on real HAOS:

- [x] clean install
- [x] start/stop/restart
- [ ] reboot
- [x] DNS UDP
- [x] DNS TCP
- [x] upstream resolution
- [x] blocking
- [x] Pi-hole UI
- [x] App config changes
- [x] profile changes
- [x] custom blocklists
- [x] backup
- [x] restore
- [x] upgrade
- [x] logs contain no password
- [x] UDP 67 closed
- [x] no DHCP service
- [x] no unnecessary capabilities

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
