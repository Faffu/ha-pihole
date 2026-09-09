#!/usr/bin/env bash
# Self-check for blocklist profile resolution. No network, no Pi-hole needed.
set -euo pipefail

# shellcheck source=../pihole/blocklists.sh
source "$(dirname "$0")/../pihole/blocklists.sh"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

opts() { printf '%s' "$1" >"${tmp}/o.json"; echo "${tmp}/o.json"; }

assert_eq() {
    if [ "$1" != "$2" ]; then
        echo "FAIL: expected [$2] got [$1]" >&2
        exit 1
    fi
}

# Default profile is balanced: HaGeZi Multi PRO only.
assert_eq "$(desired_lists "$(opts '{}')")" "${HAGEZI_PRO}"

# Security adds TIF on top of PRO.
assert_eq "$(desired_lists "$(opts '{"blocklist_profile":"security"}')")" \
    "$(printf '%s\n%s' "${HAGEZI_PRO}" "${HAGEZI_TIF}")"

# Strict swaps PRO for PRO++ rather than stacking both.
assert_eq "$(desired_lists "$(opts '{"blocklist_profile":"strict"}')")" "${HAGEZI_PRO_PLUS}"

# "none" leaves only the user's custom lists.
assert_eq "$(desired_lists "$(opts '{"blocklist_profile":"none","custom_blocklists":["https://example.com/a.txt"]}')")" \
    "https://example.com/a.txt"

# Custom lists are appended and duplicates collapse.
assert_eq "$(desired_lists "$(opts "{\"custom_blocklists\":[\"${HAGEZI_PRO}\",\"https://example.com/b.txt\"]}")")" \
    "$(printf '%s\n%s' "${HAGEZI_PRO}" "https://example.com/b.txt")"

# An unknown profile must not silently resolve to a list.
assert_eq "$(desired_lists "$(opts '{"blocklist_profile":"bogus"}')" 2>/dev/null)" ""

echo "PASS: blocklist profile resolution"
