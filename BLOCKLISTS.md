# Blocklist Policy

## Philosophy

The default configuration should maximize useful blocking while minimizing breakage and maintenance overhead.

Do not enable several overlapping aggregate lists by default. Pi-hole already deduplicates domains during Gravity processing, but redundant sources still increase download/update complexity and make false-positive diagnosis harder.

## Profiles

### Balanced — DEFAULT

Use:

```text
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt
```

Source: HaGeZi Multi PRO.

This is the recommended general-purpose profile for a technically managed home network.

Goals:
- ads
- trackers
- telemetry
- malware/scam coverage
- reasonable compatibility

### Security

Use Balanced plus HaGeZi TIF only after resource checks.

Full TIF:

```text
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt
```

Important:
- TIF is very large.
- It is not a default list.
- measure RAM usage and Gravity update duration before enabling it automatically on low-memory HAOS systems.
- where available, consider a smaller official TIF variant.

### Strict

Use:

```text
https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.plus.txt
```

Optional TIF after resource checks.

Strict is for users willing to troubleshoot false positives. Warn before switching.

Do not make HaGeZi Ultimate the normal strict preset without a deliberate future decision: it deliberately trades compatibility for maximum blocking.

## Optional sources

### StevenBlack Unified Hosts

```text
https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
```

Keep disabled by default when HaGeZi is active because the aggregate sets overlap substantially.

Allow users to add it manually or via an optional compatibility preset.

## Advanced security sources

Possible future opt-ins:
- HaGeZi DGA
- HaGeZi NRD
- Dynamic DNS abuse
- Most Abused TLDs

Rules:
- NRD and DGA are alternatives for normal use; do not blindly stack both.
- treat NRD as aggressive because newly registered legitimate domains can be blocked.
- treat whole-TLD blocking as aggressive.
- category lists must never be silently enabled.

## Category filtering

Keep separate optional profiles/categories for:
- gambling
- adult
- social media
- piracy
- other policy/content categories

These are policy choices, not baseline network security.

## App behavior

The App should maintain metadata identifying App-managed adlists.

Required semantics:
- first install adds the selected preset;
- restart does not duplicate lists;
- upgrade does not duplicate lists;
- user-added lists remain untouched;
- switching profile only changes App-managed entries;
- custom list configuration adds/maintains only lists explicitly owned by the App configuration;
- disabling App profile management should not erase user lists.

## URL stability

Prefer maintainers' documented CDN/raw URLs.

Do not mirror third-party lists into this repository unless licensing, update automation and provenance are explicitly handled.

## Review checklist for new default lists

Before adding a source to a built-in profile, document:
1. maintainer/repository;
2. update frequency;
3. license;
4. intended coverage;
5. overlap with current sources;
6. false-positive reputation;
7. approximate size;
8. effect on RAM;
9. effect on Gravity update time;
10. why it improves the profile.
