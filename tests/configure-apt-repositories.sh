#!/bin/sh
set -eu

# shellcheck disable=SC1091
. /etc/os-release

if [ "${ID:-}" != "debian" ] || [ "${VERSION_CODENAME:-}" != "bullseye" ]; then
  exit 0
fi

echo "Using Debian archive repositories for historical Bullseye tests"

# Official Debian images use sources.list or debian.sources. Replace both so
# Bullseye's retired live repositories cannot supply stale package indexes.
rm -f /etc/apt/sources.list.d/debian.sources
cat > /etc/apt/sources.list <<'EOF'
deb [check-valid-until=no] http://archive.debian.org/debian bullseye main
deb [check-valid-until=no] http://archive.debian.org/debian bullseye-updates main
deb [check-valid-until=no] http://archive.debian.org/debian-security bullseye-security main
EOF

# Expiry checks are disabled only for these frozen archives; APT still verifies
# repository signatures using the image's Debian archive keyring.
rm -rf /var/lib/apt/lists/*
