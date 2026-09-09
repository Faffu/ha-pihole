#!/usr/bin/env bash
# Verifies that config.yaml, the changelog and (on a tag build) the git tag
# all agree on the release version.
set -euo pipefail

cd "$(dirname "$0")/.."

config_version="$(sed -n 's/^version:[[:space:]]*"\{0,1\}\([^"]*\)"\{0,1\}[[:space:]]*$/\1/p' pihole/config.yaml)"
changelog_version="$(sed -n 's/^##[[:space:]]*\[\{0,1\}\([0-9][^]) ]*\).*/\1/p' pihole/CHANGELOG.md | head -n1)"

fail=0

if [ -z "${config_version}" ]; then
    echo "ERROR: no version found in pihole/config.yaml" >&2
    exit 1
fi

if [ "${config_version}" != "${changelog_version}" ]; then
    echo "ERROR: config.yaml is ${config_version} but CHANGELOG.md is ${changelog_version}" >&2
    fail=1
fi

tag="${GITHUB_REF_NAME:-}"
if [ -n "${tag}" ] && [ "${GITHUB_REF_TYPE:-}" = "tag" ]; then
    if [ "${tag#v}" != "${config_version}" ]; then
        echo "ERROR: git tag ${tag} does not match config.yaml version ${config_version}" >&2
        fail=1
    fi
fi

if grep -qE '^\s+(amd64|aarch64):\s+\S+:latest\s*$' pihole/build.yaml; then
    echo "ERROR: build.yaml uses a floating 'latest' base image" >&2
    fail=1
fi

if [ "${fail}" -eq 0 ]; then
    echo "Version check passed: ${config_version}"
fi
exit "${fail}"
