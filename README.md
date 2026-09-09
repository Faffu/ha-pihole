# Pi-hole for Home Assistant

A Home Assistant OS App that runs Pi-hole v6 as a DNS filtering server. DNS
only, no DHCP.

## Install

In Home Assistant, open Settings, Add-ons, Add-on Store, then the three-dot
menu, Repositories, and add this repository URL. Install Pi-hole from the entry
that appears.

The App documentation is in [pihole/DOCS.md](pihole/DOCS.md).

## What it does

- Pi-hole v6, pinned to a specific upstream image, never a floating tag.
- DNS on 53/tcp and 53/udp through Supervisor port mapping, no host networking.
- No DHCP: 67/udp is never published, `NET_ADMIN` is never requested, and DHCP
  is forced off in the Pi-hole configuration on every start.
- State persisted in `/data` and covered by Supervisor backups.
- Blocklist profiles built on HaGeZi, with `balanced` as the default. Lists you
  add yourself are never removed by the App.
- amd64 and aarch64 images published to GHCR.

## Repository layout

| Path | Purpose |
| --- | --- |
| `pihole/` | The App itself: config, Dockerfile, startup scripts, docs. |
| `scripts/check_version.sh` | Version consistency check used by CI. |
| `tests/` | Offline self-checks. |
| `PROJECT_PROMPT.md` | Authoritative specification. |
| `BLOCKLISTS.md` | Blocklist policy. |
| `TASKS.md` | Phased implementation plan. |
| `AGENTS.md`, `CLAUDE.md` | Agent development instructions. |

## Testing on Home Assistant OS

This repository is private, so Supervisor cannot add it as an App repository
and cannot pull the GHCR images without credentials. Install it as a local App
instead, which also makes Supervisor build the image on the machine you are
testing on:

1. Copy the `pihole/` directory to `/addons/pihole` on the Home Assistant host,
   over Samba or the SSH App.
2. Delete the `image:` line from `/addons/pihole/config.yaml`. While that line
   is present Supervisor pulls a published image instead of building locally.
3. In Home Assistant, Settings, Add-ons, Add-on Store, three-dot menu, Check
   for updates. Pi-hole appears under Local add-ons.

Making the repository public, or configuring registry credentials in
Supervisor, is what enables the normal repository install path.

## Development

```bash
shellcheck -e SC1091 -x pihole/*.sh scripts/*.sh tests/*.sh
./tests/test_blocklists.sh
./scripts/check_version.sh
docker build -t ha-pihole:dev pihole
```
