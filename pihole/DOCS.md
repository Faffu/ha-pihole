# Pi-hole App documentation

Pi-hole v6 as a Home Assistant App. It provides DNS filtering only. DHCP stays
with your router.

## Installation

1. In Home Assistant go to Settings, Add-ons, Add-on Store.
2. Open the three-dot menu, choose Repositories, and add
   `https://github.com/Faffu/ha-pihole`.
3. Install Pi-hole from the new repository entry.
4. Set at least `web_password` before starting.
5. Start the App and open the Web UI.

## Before you point your network at it

Give the Home Assistant host a static IP address, either a DHCP reservation on
your router or a static configuration in Settings, System, Network. If the host
address changes, every client that was told to use it for DNS loses name
resolution.

Then set your router's DHCP server to advertise the Home Assistant host address
as the LAN DNS server. Pi-hole in this App never serves DHCP, so the router
keeps that job.

## Options

| Option | Meaning |
| --- | --- |
| `timezone` | IANA timezone for logs and statistics. Default `Europe/Rome`. |
| `upstream_dns` | Resolvers Pi-hole forwards to. Default Cloudflare. |
| `web_password` | Admin password. Empty means a random one is generated. |
| `dnssec` | Validate DNSSEC signatures. |
| `conditional_forwarding` | `cidr,router-ip[,local-domain]`, empty to disable. |
| `manage_blocklists` | Whether the App maintains the profile's adlists. |
| `blocklist_profile` | `balanced`, `security`, `strict` or `none`. |
| `custom_blocklists` | Extra list URLs kept installed alongside the profile. |

If `web_password` is empty, a random password is generated on first start and
written to `/data/.web_password` inside the App container. It is never printed
to the log. Setting `web_password` in the options is the supported way to know
what your password is.

## Ports

DNS is published on 53/tcp and 53/udp on the host. The admin interface is
published on host port 8080 by default and you can change it in the App's
network settings.

Port 53 must be free on the Home Assistant host. Home Assistant OS itself does
not bind host port 53, but another App might. If the App fails to start with a
bind error on port 53, stop whichever other App is using it.

Never forward the admin port from the Internet. Reach it over your LAN or
through a VPN.

## Web UI and Ingress

Ingress is deliberately not used. Home Assistant Ingress serves an App under a
generated path such as `/api/hassio_ingress/<token>/`, and that token changes.
Pi-hole v6 serves its interface from a webroot fixed in its own configuration,
so it would need either a token that cannot be known at start time or URL
rewriting in front of it. Both are fragile, so the App exposes a normal Web UI
link instead. The App still appears in the sidebar through the `webui` link.

## IPv4 and IPv6

The App listens on both. If your router also advertises itself or a public
resolver as an IPv6 DNS server, clients will bypass Pi-hole over IPv6 and
filtering will look broken at random. Either advertise the Home Assistant host
address for IPv6 DNS as well, or disable IPv6 DNS advertisement on the router.

## Verifying that filtering works

Run these from a LAN client, replacing the address with your Home Assistant
host:

```bash
nslookup example.com 192.168.1.10
dig @192.168.1.10 example.com
dig @192.168.1.10 -p 53 +tcp example.com
```

A domain that the blocklist covers should answer `0.0.0.0` or `NXDOMAIN`:

```bash
dig @192.168.1.10 googleads.g.doubleclick.net
```

Then open the Pi-hole query log and confirm the queries appear there.

## If DNS breaks

Filtering failures look like a network outage, so know the escape route before
you need it.

1. On your router, change the advertised DNS server back to the router itself
   or to `1.1.1.1`, then renew the DHCP lease on the affected client.
2. Or set a resolver manually on the one client that is broken.
3. Home Assistant itself keeps using the Supervisor's own resolver, so the
   Home Assistant UI stays reachable even when Pi-hole is down. Stop or
   reconfigure the App from there.

## Switching blocklist profiles

Change `blocklist_profile` and restart the App. The App adds the lists the new
profile needs, removes only the lists it previously added itself, and then runs
Gravity once. Lists you added through the Pi-hole interface are never removed.

`security` adds the HaGeZi Threat Intelligence Feeds, which is a large list.
Watch memory use on low-memory hardware such as a Raspberry Pi with 1 GB of
RAM. `strict` uses HaGeZi Multi PRO++, which blocks more and breaks more.

## Adding custom blocklists

Two ways, and they behave differently.

Put the URL in `custom_blocklists` if you want the App to keep it installed.
The App will re-add it if it goes missing and will remove it when you take it
out of the option.

Add it through the Pi-hole interface if you want to own it yourself. The App
never touches lists it did not create.

The App identifies its own entries by an `[ha-app]` prefix in the adlist
comment field. Do not use that prefix on lists you add by hand.

## False positives

When a site breaks, open the Pi-hole query log, find the blocked domain, and
add it to the allowlist through the Pi-hole interface. Allowlist entries live
in Pi-hole's own database and survive App restarts and upgrades.

If a profile blocks too much for your household, move from `strict` to
`balanced`, or from `balanced` to `none` plus your own lists.

## Upgrades, backup and restore

All Pi-hole state lives in `/data` inside the App: configuration, the gravity
database, adlists, groups, clients, local DNS records and allowlists. Upgrading
the App replaces the container but keeps `/data`, so nothing is lost.

Supervisor backups of this App are cold. Home Assistant stops the App, copies
`/data`, and starts it again, because copying the SQLite databases while
Pi-hole is writing to them can produce a corrupt copy. DNS is unavailable for
the length of the backup, which is normally seconds but grows with the size of
the gravity database.

Restoring a backup restores the whole `/data` directory. After a restore, check
that the adlists and the query log look right before pointing clients back.

## Security notes

- The container runs with Docker's default capabilities. It does not request
  `NET_ADMIN`, does not run privileged, does not use host networking, host PID
  or host D-Bus, and mounts no devices.
- 67/udp is never published, and DHCP is forced off in the Pi-hole
  configuration on every start.
- An AppArmor profile ships with the App and denies `net_admin`, mounting and
  writes to kernel tunables.
- The admin password is passed to Pi-hole through the environment and is never
  written to the log.
- Publishing DNS on host port 53 makes the resolver reachable from your whole
  LAN. Do not forward port 53 from the Internet: an open resolver will be
  abused for amplification attacks.
