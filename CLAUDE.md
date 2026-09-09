# CLAUDE.md — Claude Code Project Guide

## Project

This repository builds a Pi-hole v6 App for Home Assistant OS / Supervisor.

The App provides DNS filtering only. DHCP is intentionally excluded.

Start by reading:
1. `PROJECT_PROMPT.md`
2. `BLOCKLISTS.md`
3. `TASKS.md`

## Core constraints

- Pi-hole v6.
- Home Assistant OS App, not a generic Docker Compose deployment.
- amd64 + aarch64.
- expose 53/TCP and 53/UDP.
- never expose 67/UDP.
- no Pi-hole DHCP UI/options.
- avoid `NET_ADMIN`.
- avoid `host_network` unless port mapping proves insufficient.
- persist `/etc/pihole`.
- no floating production image tags.
- protect admin credentials.
- do not silently overwrite user-created Pi-hole settings.

## Implementation principles

Use official current Home Assistant Developer documentation and Pi-hole documentation as primary references.

When documentation and existing code disagree, flag the discrepancy before making a breaking change.

Prefer simple Bash for thin startup glue. Do not add Python/Node dependencies without a clear need.

All startup logic must be idempotent.

Pi-hole profile/blocklist management must distinguish:
- App-managed lists
- user-managed lists

Never delete unknown/user-managed lists during an upgrade or profile change.

## Blocklist policy

Default: HaGeZi Multi PRO only.

Security/strict profiles may add more aggressive sources as documented in `BLOCKLISTS.md`.

Avoid "more lists = better" behavior.

## Validation expectations

For shell changes:
- ShellCheck
- syntax check

For YAML:
- parser validation
- Home Assistant App config validation if tooling is available

For container changes:
- local image build
- startup smoke test when possible

For release changes:
- verify image tag matches `config.yaml` version.

Do not claim tests you did not run.

## Response style during coding

At the end of a task provide:
- Summary
- Files changed
- Tests run
- Remaining risks / required HAOS validation

Keep reports concise and factual.
