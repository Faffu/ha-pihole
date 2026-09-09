# Changelog

## 0.1.2

- Fix Pi-hole failing to start under the App's AppArmor profile. The profile
  enumerated capabilities and left out `setfcap`, which Pi-hole needs to put
  file capabilities on `pihole-FTL` so it can bind port 53 as a non-root user.
  The profile now allows the container's default capability set and denies
  `net_admin` explicitly, which is the confinement that actually matters here.
- Stop downloading a blocklist nobody asked for on a fresh install. Pi-hole
  created its own default adlist and ran Gravity against it before the selected
  profile was applied, so every new install fetched an unrelated list and then
  ran Gravity a second time.

## 0.1.1

- Fix a startup crash when `web_password` is empty, which is the default. The
  random password generator piped `/dev/urandom` into `head`, so `head` exiting
  killed the producer with SIGPIPE and `set -o pipefail` aborted the script
  before Pi-hole ever started. It now reads a fixed number of bytes instead.
- Add a self-check that runs the startup script's option translation, including
  the empty-password path that the crash was hiding in.

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
