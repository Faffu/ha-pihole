# Project Prompt — Pi-hole App for Home Assistant OS

You are a senior Home Assistant App (formerly Add-on), container, Linux networking, and Pi-hole engineer.

## Goal

Build a production-quality Home Assistant OS App that runs Pi-hole v6 as a DNS filtering server managed by Home Assistant Supervisor.

The App MUST provide DNS filtering only. Pi-hole DHCP functionality is explicitly out of scope.

The target is a clean, maintainable, secure repository that can be developed and maintained with both OpenAI Codex and Claude Code.

## Primary requirements

1. Run Pi-hole v6 inside a Home Assistant App container.
2. Support Home Assistant OS / Supervisor.
3. Support at least:
   - amd64
   - aarch64
4. Expose DNS on:
   - 53/udp
   - 53/tcp
5. Do NOT implement or expose DHCP:
   - no UDP 67
   - no DHCP configuration UI
   - no NET_ADMIN solely for DHCP
6. Persist Pi-hole state in a Supervisor-managed persistent location.
7. Persist `/etc/pihole`.
8. Do not depend on `/etc/dnsmasq.d` for a fresh Pi-hole v6 installation unless a concrete technical need is documented.
9. Configure Pi-hole v6 through supported `FTLCONF_*` environment/config mechanisms.
10. Set `FTLCONF_dns_listeningMode=ALL` when using bridge networking.
11. Avoid `host_network` unless testing proves standard port mapping cannot meet the DNS requirements.
12. Provide configurable upstream resolvers.
13. Default timezone: `Europe/Rome`, but make it configurable.
14. Provide Pi-hole web administration.
15. Evaluate Home Assistant Ingress carefully:
    - use it only if Pi-hole's web UI behaves correctly under the Home Assistant ingress path/proxy model;
    - do not add fragile URL rewriting hacks without documenting them;
    - if Ingress is not robust, expose a normal Web UI URL instead.
16. Never expose Pi-hole's admin page to the public Internet by default.
17. Integrate with Home Assistant Supervisor lifecycle:
    - startup
    - stop
    - restart
    - logs
    - watchdog/healthcheck if practical
    - backups
18. Publish prebuilt multi-architecture images to GHCR.
19. Pin tested Pi-hole/container/base versions. Do not use floating `latest` in production releases.
20. Add CI validation and image builds.

## Home Assistant repository layout

Use the current Home Assistant App repository format.

Suggested structure:

```text
ha-pihole/
├── repository.yaml
├── README.md
├── LICENSE
├── AGENTS.md
├── CLAUDE.md
├── BLOCKLISTS.md
├── TASKS.md
├── .github/
│   └── workflows/
│       ├── lint.yml
│       ├── build.yml
│       └── release.yml
└── pihole/
    ├── config.yaml
    ├── Dockerfile
    ├── run.sh
    ├── README.md
    ├── DOCS.md
    ├── CHANGELOG.md
    ├── apparmor.txt
    ├── translations/
    │   ├── en.yaml
    │   └── it.yaml
    └── rootfs/
        └── ...
```

Modify the layout when justified by current Home Assistant or Pi-hole best practices.

## App configuration

The UI should expose only useful options. Keep defaults safe.

Candidate options:

```yaml
timezone: Europe/Rome
upstream_dns:
  - 1.1.1.1
  - 1.0.0.1
web_password: ""
dnssec: false
conditional_forwarding: false
blocklist_profile: balanced
custom_blocklists: []
```

Do not store or print passwords unnecessarily. Prefer Supervisor-supported secret-safe patterns where possible.

### Networking

Default approach:

```yaml
ports:
  53/tcp: 53
  53/udp: 53
```

Verify that Home Assistant OS has no conflicting host service using these ports for Apps.

If port 53 cannot be mapped safely, document the exact reason and propose the smallest viable alternative.

The router remains responsible for DHCP and should distribute the HAOS device IP as LAN DNS.

## Pi-hole v6

Follow current Pi-hole v6 Docker configuration, not v5-era environment variables.

At minimum account for:

- `TZ`
- `FTLCONF_webserver_api_password`
- `FTLCONF_dns_upstreams`
- `FTLCONF_dns_listeningMode`

Use a persistent `/etc/pihole`.

Do not blindly copy the official Docker image's entrypoint assumptions into a Home Assistant App. Confirm process supervision, PID 1 behavior, signals, shutdown and persistence.

## Blocklist design

Do NOT blindly combine many overlapping mega-lists.

Implement selectable profiles.

### `balanced` — default

Primary list:

- HaGeZi Multi PRO
- URL:
  `https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt`

Rationale:
- broad ads/tracking/telemetry/malware/scam coverage;
- maintained;
- suitable as a standalone consolidated list;
- less disruptive than Pro++ / Ultimate.

Do not enable StevenBlack or OISD in addition to HaGeZi Pro by default because most coverage overlaps and extra lists mainly increase Gravity size and troubleshooting complexity.

### `security`

Use:
- HaGeZi Multi PRO
- HaGeZi Threat Intelligence Feeds (TIF), preferably a resource-appropriate variant after testing memory usage.

Full TIF:
`https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt`

The full TIF is very large. Do not make it the default. Measure memory and Gravity update impact on representative HAOS hardware before enabling it automatically.

### `strict`

Use:
- HaGeZi Multi PRO++
- optionally TIF if memory requirements are met

PRO++:
`https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.plus.txt`

Warn users that Pro++ is more likely to cause false positives or app/site breakage.

### Optional compatibility list

StevenBlack Unified Hosts:
`https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`

Expose it as optional only. Do not combine it with HaGeZi by default.

### Advanced optional security lists

Consider but DO NOT enable by default:
- HaGeZi DGA
- HaGeZi NRD
- Dynamic DNS abuse
- Most Abused TLDs

NRD and DGA must not both be enabled by default; DGA is the narrower high-entropy subset/use case.

Keep category-specific lists such as gambling/adult/social separate from the core security/adblocking profiles.

## Blocklist provisioning

On first installation:
1. Determine selected profile.
2. Insert required adlists into Pi-hole's supported configuration/database path using a supported Pi-hole mechanism.
3. Avoid brittle direct SQLite modifications unless the Pi-hole project explicitly supports the schema being manipulated.
4. Run Gravity only when required.
5. Do not overwrite user-added blocklists on every restart.
6. Track which lists were installed by the App so profile migrations can be handled safely.
7. Custom lists supplied by the user must survive upgrades.
8. App upgrades must not unexpectedly remove user-managed adlists.

## Security

Follow least privilege.

- no privileged container unless proven necessary;
- no NET_ADMIN for v1;
- no DHCP capability;
- no host PID;
- no host D-Bus;
- no unnecessary device mounts;
- no public web exposure;
- sanitize configuration;
- do not log passwords;
- include an AppArmor profile where practical;
- use read-only mounts where possible;
- document port 53 implications.

## Backups

Ensure Supervisor backups contain all persistent Pi-hole state required to restore:
- configuration
- gravity/adlist metadata where appropriate
- local DNS configuration
- client/group configuration
- custom lists

Prefer cold backup if that materially improves consistency.

## CI/CD

Implement:
- YAML validation
- ShellCheck
- Docker/build validation
- Home Assistant App configuration validation
- amd64 image build
- aarch64 image build
- GHCR publishing
- version/tag consistency checks
- release workflow

Use immutable release tags.

## Documentation

README/DOCS must explain:

1. Installation as a custom Home Assistant App repository.
2. Static IP recommendation for the HAOS host.
3. Router DHCP must advertise the HAOS IP as DNS.
4. Pi-hole itself does not provide DHCP in this project.
5. Port 53 conflicts.
6. IPv4 and IPv6 implications.
7. How to verify filtering:
   - `nslookup`
   - `dig`
   - Pi-hole query log
8. How to recover if DNS breaks.
9. How to switch profiles.
10. How to add custom blocklists.
11. False-positive troubleshooting.
12. Upgrade and backup/restore.
13. Security considerations.
14. Ingress/Web UI limitations if any.

## Tests / acceptance criteria

The project is not complete until these are demonstrated:

- App installs on HAOS.
- App starts automatically.
- Pi-hole FTL remains healthy.
- TCP/UDP port 53 is reachable from another LAN device.
- A LAN client can resolve normal domains through Pi-hole.
- A known blocked test domain is blocked.
- Pi-hole can reach configured upstream resolvers.
- Rebooting HAOS does not lose configuration.
- Updating the App does not lose configuration.
- Backup and restore preserve state.
- No DHCP listener exists.
- UDP 67 is not exposed.
- No unnecessary `NET_ADMIN`.
- amd64 image builds.
- aarch64 image builds.
- blocklist profile installation is idempotent.
- custom blocklists survive restart/update.
- logs contain no plaintext admin password.
- failure modes produce actionable logs.

## Development workflow

Work incrementally.

For every task:
1. inspect the existing repository first;
2. state assumptions briefly;
3. make the smallest coherent change;
4. validate it;
5. update docs/tests;
6. report files changed, tests run and unresolved risks.

Do not fabricate successful HAOS runtime tests when only static/container tests were performed.

## Deliverables

Produce a repository ready to push to GitHub, including:
- complete Home Assistant App;
- multi-arch build;
- GHCR workflow;
- documentation;
- App configuration translations in English and Italian;
- blocklist profiles;
- tests;
- security notes;
- release process.

Prioritize reliability and maintainability over feature count.
