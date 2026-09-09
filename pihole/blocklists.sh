#!/usr/bin/env bash
# Reconciles the App-managed Pi-hole adlists with the selected profile.
#
# Ownership is tracked through the adlist comment field: every entry this App
# creates carries MARKER. Entries without it were created by the user and are
# never modified or deleted.
set -euo pipefail

OPTIONS=${OPTIONS:-/data/options.json}
API=${API:-http://127.0.0.1/api}
MARKER='[ha-app]'
GRAVITY_DB=${GRAVITY_DB:-/etc/pihole/gravity.db}

HAGEZI_PRO='https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.txt'
HAGEZI_PRO_PLUS='https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/pro.plus.txt'
HAGEZI_TIF='https://cdn.jsdelivr.net/gh/hagezi/dns-blocklists@latest/adblock/tif.txt'

# Pi-hole ships one default adlist and imports it on the very first start.
# It overlaps almost entirely with HaGeZi, so on first run only it is disabled
# rather than deleted. Anything the user does to it afterwards sticks.
PIHOLE_DEFAULT_LIST='https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts'
PIHOLE_DEFAULT_COMMENT='Migrated from /etc/pihole/adlists.list'

log() { echo "  [ha/blocklists] $*" >&2; }

# profile_lists <profile> -> one URL per line.
# Deliberately small: overlapping mega-lists add Gravity size and make
# false positives harder to diagnose without blocking much more.
profile_lists() {
    case "$1" in
        balanced) printf '%s\n' "${HAGEZI_PRO}" ;;
        security) printf '%s\n' "${HAGEZI_PRO}" "${HAGEZI_TIF}" ;;
        strict)   printf '%s\n' "${HAGEZI_PRO_PLUS}" ;;
        none)     : ;;
        *)        log "Unknown profile '$1', treating as 'none'." ; return 1 ;;
    esac
}

# desired_lists <options.json> -> profile lists plus custom lists, deduplicated.
desired_lists() {
    local file=$1 profile
    profile="$(jq -r '.blocklist_profile // "balanced"' "${file}")"
    {
        profile_lists "${profile}" || true
        jq -r '.custom_blocklists[]? | select(. != "")' "${file}"
    } | awk 'NF && !seen[$0]++'
}

api() {
    local method=$1 path=$2
    shift 2
    curl -sS -m 300 -X "${method}" "${API}${path}" \
        -H "X-FTL-SID: ${SID}" -H 'Content-Type: application/json' "$@"
}

authenticate() {
    local body sid deadline
    body="$(jq -nc --arg p "${FTLCONF_webserver_api_password:-}" '{password: $p}')"
    deadline=$(( SECONDS + 120 ))
    while [ "${SECONDS}" -lt "${deadline}" ]; do
        sid="$(curl -sS -m 10 -X POST "${API}/auth" \
            -H 'Content-Type: application/json' --data "${body}" \
            2>/dev/null | jq -r '.session.sid // empty')" || true
        if [ -n "${sid:-}" ]; then
            SID="${sid}"
            return 0
        fi
        sleep 3
    done
    log "ERROR: could not authenticate against the Pi-hole API within 120s."
    log "Blocklists were left unchanged. Pi-hole itself is unaffected."
    return 1
}

# On a fresh install, turn off the adlist Pi-hole ships by default so the
# selected profile is what actually gets used. Only touches an entry that
# still carries Pi-hole's own untouched migration comment.
disable_pihole_default() {
    local entry
    entry="$(api GET '/lists?type=block' | jq -r \
        --arg a "${PIHOLE_DEFAULT_LIST}" --arg c "${PIHOLE_DEFAULT_COMMENT}" \
        '.lists[]? | select(.address == $a and (.comment // "") == $c and .enabled)
         | {comment, type, groups, enabled: false}')"
    [ -n "${entry}" ] || return 0
    log "Disabling Pi-hole's default adlist, the selected profile covers it."
    api PUT "/lists/$(jq -rn --arg a "${PIHOLE_DEFAULT_LIST}" '$a | @uri')?type=block" \
        --data "${entry}" >/dev/null
}

main() {
    local desired current managed add remove changed=0 url first_run=0
    [ -s "${GRAVITY_DB}" ] || first_run=1
    desired="$(desired_lists "${OPTIONS}")"

    authenticate || return 1

    if [ "${first_run}" -eq 1 ] && ! grep -qxF "${PIHOLE_DEFAULT_LIST}" <<<"${desired}"; then
        disable_pihole_default
    fi

    current="$(api GET '/lists?type=block' | jq -r '.lists[]?.address')"
    managed="$(api GET '/lists?type=block' \
        | jq -r --arg m "${MARKER}" \
          '.lists[]? | select((.comment // "") | startswith($m)) | .address')"

    add="$(comm -13 <(sort <<<"${current}") <(sort <<<"${desired}"))"
    remove="$(comm -23 <(sort <<<"${managed}") <(sort <<<"${desired}"))"

    while read -r url; do
        [ -n "${url}" ] || continue
        log "Adding App-managed adlist: ${url}"
        api POST '/lists?type=block' --data "$(jq -nc --arg a "${url}" \
            --arg c "${MARKER} managed by the Home Assistant Pi-hole App" \
            '{address: $a, comment: $c, groups: [0], enabled: true}')" >/dev/null
        changed=1
    done <<<"${add}"

    while read -r url; do
        [ -n "${url}" ] || continue
        log "Removing App-managed adlist no longer in the profile: ${url}"
        api POST '/lists:batchDelete' \
            --data "$(jq -nc --arg a "${url}" '[{item: $a, type: "block"}]')" >/dev/null
        changed=1
    done <<<"${remove}"

    # A fresh install has no gravity data yet even when the adlists already
    # match, so refresh anyway.
    if [ "${first_run}" -eq 1 ]; then
        changed=1
    fi

    if [ "${changed}" -eq 0 ]; then
        log "Adlists already match the selected profile. Gravity not run."
        return 0
    fi

    log "Running Gravity. This can take several minutes on first install."
    api POST '/action/gravity' >/dev/null
    log "Gravity update finished."
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
