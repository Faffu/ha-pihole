# Pi-hole

Network-wide DNS filtering for Home Assistant OS, built on Pi-hole v6.

- DNS on 53/tcp and 53/udp, no host networking.
- No DHCP. Your router keeps that job, and 67/udp is never published.
- HaGeZi Multi PRO as the default blocklist, with `security`, `strict` and
  `none` profiles and room for your own lists.
- All state persisted in `/data` and included in Supervisor backups.
- amd64 and aarch64.

Set `web_password`, start the App, then point your router's DHCP server at the
Home Assistant host as the LAN DNS server.

Full documentation is in [DOCS.md](DOCS.md).
