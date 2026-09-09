#!/usr/bin/env bash
# Exercises the option-translation half of run.sh without starting Pi-hole.
# Covers the empty-password path, which is what the App does out of the box.
set -euo pipefail

RUN="$(dirname "$0")/../pihole/run.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

run_with() {
    printf '%s' "$1" >"${tmp}/options.json"
    rm -rf "${tmp}/pihole" "${tmp}/etc-pihole"
    env -i PATH="${PATH}" HA_PIHOLE_DRY_RUN=1 \
        OPTIONS="${tmp}/options.json" \
        DATA="${tmp}/pihole" \
        PW_FILE="${tmp}/pw" \
        ETC_PIHOLE="${tmp}/etc-pihole" \
        bash "${RUN}" >"${tmp}/out" 2>&1
}

fail() { echo "FAIL: $1" >&2; sed 's/^/    /' "${tmp}/out" >&2; exit 1; }

# Out of the box: no password set. This must not abort the script.
rm -f "${tmp}/pw"
run_with '{"timezone":"Europe/Rome","upstream_dns":["1.1.1.1","1.0.0.1"],"web_password":"","dnssec":false,"conditional_forwarding":"","manage_blocklists":true,"blocklist_profile":"balanced","custom_blocklists":[]}' \
    || fail "run.sh exited non-zero with an empty web_password"
[ -s "${tmp}/pw" ] || fail "no password was generated"
[ "$(wc -c <"${tmp}/pw")" -ge 16 ] || fail "generated password is too short"
grep -q "$(cat "${tmp}/pw")" "${tmp}/out" && fail "generated password was printed to the log"

# The generated password must be stable across restarts.
first="$(cat "${tmp}/pw")"
run_with '{"web_password":""}' || fail "second run failed"
[ "$(cat "${tmp}/pw")" = "${first}" ] || fail "password was regenerated on restart"

# /etc/pihole is redirected into the persistent volume.
[ "$(readlink "${tmp}/etc-pihole")" = "${tmp}/pihole" ] || fail "etc/pihole was not linked into DATA"

# An explicit password is used as-is and never logged.
run_with '{"web_password":"hunter2hunter2"}' || fail "explicit password run failed"
grep -q hunter2hunter2 "${tmp}/out" && fail "explicit password was printed to the log"

# Empty upstream_dns must not produce an empty FTL upstream list.
run_with '{"upstream_dns":[]}' || fail "empty upstream_dns run failed"
grep -q "falling back to" "${tmp}/out" || fail "no fallback for empty upstream_dns"

echo "PASS: run.sh option translation"
