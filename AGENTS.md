# AGENTS.md — Codex Development Instructions

## Mission

Develop and maintain a production-quality Pi-hole v6 Home Assistant OS App.

Read `PROJECT_PROMPT.md`, `BLOCKLISTS.md` and `TASKS.md` before changing code.

## Non-negotiable constraints

- DNS only.
- DHCP is out of scope.
- Do not expose UDP 67.
- Do not request `NET_ADMIN` unless a later documented requirement unrelated to DHCP makes it unavoidable.
- Prefer mapped `53/tcp` and `53/udp` over host networking.
- Persist `/etc/pihole`.
- Target `amd64` and `aarch64`.
- Follow Pi-hole v6 configuration conventions (`FTLCONF_*`).
- Follow current Home Assistant App repository/config conventions.
- Do not use floating production image versions.
- Do not leak passwords into logs, generated files committed to git, CI output or command output.

## Agent behavior

Before implementing a change:
1. inspect relevant files;
2. identify current behavior;
3. verify assumptions against current official documentation when network access is available;
4. prefer official Home Assistant and Pi-hole documentation over blog posts.

After implementing:
1. run relevant linters/tests;
2. validate YAML;
3. run ShellCheck on shell scripts;
4. build the container for the local architecture if possible;
5. report exactly what was tested;
6. never claim HAOS runtime compatibility unless actually tested on HAOS.

## Architecture rules

Keep Home Assistant glue separate from Pi-hole state.

Prefer:
- Supervisor App options -> startup translation layer -> Pi-hole supported config.
- persistent data under Supervisor-managed app storage.
- idempotent configuration.

Avoid:
- direct editing of Pi-hole databases unless officially supported;
- replacing user-managed adlists on every boot;
- hacks that depend on unstable Pi-hole internals;
- unnecessary Supervisor API privileges.

## Blocklists

Default profile is `balanced` and uses HaGeZi Multi PRO.

Profiles are defined in `BLOCKLISTS.md`.

Do not add overlapping lists to the default profile simply to increase domain count.

Any new default list requires:
- maintenance assessment;
- false-positive assessment;
- license review;
- overlap rationale;
- memory/performance assessment.

## Git discipline

Keep commits small and descriptive.

Suggested prefixes:
- `feat:`
- `fix:`
- `docs:`
- `ci:`
- `refactor:`
- `test:`
- `chore:`

Do not rewrite unrelated files.

## Definition of done

A task is complete only when implementation, validation, documentation and failure behavior are addressed.
