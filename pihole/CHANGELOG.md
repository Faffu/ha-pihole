# Changelog

## 0.1.0

Initial release.

- Pi-hole v6 as a Home Assistant App, pinned to upstream image 2026.07.2.
- DNS on 53/tcp and 53/udp through Supervisor port mapping, no host networking.
- DHCP is excluded: 67/udp is never published and NET_ADMIN is never requested.
- Pi-hole state persisted in /data and included in Supervisor backups.
- Configurable upstream resolvers, timezone, DNSSEC and conditional forwarding.
- Blocklist profiles balanced, security, strict and none, plus custom lists.
- App-managed adlists are tracked by comment marker so user lists survive
  restarts, profile changes and upgrades.
- amd64 and aarch64 images published to GHCR.
