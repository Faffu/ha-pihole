#!/usr/bin/env bash
# Home Assistant App entrypoint for Pi-hole v6.
# Translates Supervisor options into FTLCONF_* variables, then hands over to
# the upstream Pi-hole entrypoint. Everything here must be idempotent.
set -euo pipefail

OPTIONS=/data/options.json
DATA=/data/pihole
PW_FILE=/data/.web_password

opt() { jq -r "$1" "${OPTIONS}"; }

log() { echo "  [ha] $*"; }

# --- Persistence -----------------------------------------------------------
# /data is the Supervisor-managed persistent volume and is included in
# backups. Pi-hole insists on /etc/pihole, so point it at /data/pihole.
mkdir -p "${DATA}"
if [ ! -L /etc/pihole ]; then
    if [ -d /etc/pihole ]; then
        cp -an /etc/pihole/. "${DATA}/" 2>/dev/null || true
        rm -rf /etc/pihole
    fi
    ln -s "${DATA}" /etc/pihole
    log "Linked /etc/pihole to ${DATA}"
fi

# --- Timezone --------------------------------------------------------------
TZ="$(opt '.timezone // "Europe/Rome"')"
export TZ

# --- DNS -------------------------------------------------------------------
UPSTREAMS="$(opt '[.upstream_dns[]? | select(. != "")] | join(";")')"
if [ -z "${UPSTREAMS}" ]; then
    log "No upstream_dns configured, falling back to 1.1.1.1;1.0.0.1"
    UPSTREAMS="1.1.1.1;1.0.0.1"
fi
export FTLCONF_dns_upstreams="${UPSTREAMS}"

# Bridge networking hides the real client subnet from FTL, so it must accept
# queries arriving on any interface.
export FTLCONF_dns_listeningMode=ALL
FTLCONF_dns_dnssec="$(opt '.dnssec // false')"
export FTLCONF_dns_dnssec

# Conditional forwarding: "<cidr>,<router-ip>[,<local-domain>]".
CF="$(opt '.conditional_forwarding // ""')"
if [ -n "${CF}" ]; then
    export FTLCONF_dns_revServers="true,${CF}"
    log "Conditional forwarding enabled for ${CF%%,*}"
fi

# --- Unused services -------------------------------------------------------
# Pi-hole v6 also ships an NTP server. Home Assistant OS keeps the host clock,
# so it is turned off rather than left listening.
export FTLCONF_ntp_ipv4_active=false
export FTLCONF_ntp_ipv6_active=false

# --- DHCP is out of scope --------------------------------------------------
# Explicitly forced off. The App never publishes 67/udp and never requests
# NET_ADMIN, so FTL could not serve DHCP even if the setting were flipped.
export FTLCONF_dhcp_active=false

# --- Web password ----------------------------------------------------------
WEB_PASSWORD="$(opt '.web_password // ""')"
if [ -z "${WEB_PASSWORD}" ]; then
    if [ ! -s "${PW_FILE}" ]; then
        tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24 >"${PW_FILE}"
        chmod 0600 "${PW_FILE}"
    fi
    WEB_PASSWORD="$(cat "${PW_FILE}")"
    log "No web_password set in the App options."
    log "A random password was generated and stored in ${PW_FILE}."
    log "It is deliberately not printed here. Set web_password to choose your own."
fi
export FTLCONF_webserver_api_password="${WEB_PASSWORD}"
unset WEB_PASSWORD

# --- Blocklists ------------------------------------------------------------
# Runs in the background because it talks to the Pi-hole REST API, which only
# answers once FTL is up. It inherits the API password from the environment.
if [ "$(opt '.manage_blocklists // true')" = "true" ]; then
    /usr/local/bin/blocklists.sh &
else
    log "manage_blocklists is false, leaving adlists untouched."
fi

# Hand over to Pi-hole's own entrypoint so it keeps PID 1, its signal traps
# and its clean shutdown path.
exec /usr/bin/start.sh
