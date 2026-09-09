ARG BUILD_FROM=pihole/pihole:2026.07.2
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# jq parses the Supervisor options file; tzdata backs the timezone option.
# hadolint ignore=DL3018
RUN apk add --no-cache jq tzdata

COPY run.sh blocklists.sh /usr/local/bin/
RUN chmod 0755 /usr/local/bin/run.sh /usr/local/bin/blocklists.sh

# Replace the upstream entrypoint. run.sh translates Home Assistant options
# into FTLCONF_* variables and then execs the upstream start.sh, so Pi-hole
# keeps its own PID 1 signal handling and shutdown behaviour.
ENTRYPOINT ["/usr/local/bin/run.sh"]
CMD []
