#!/usr/bin/env bash
# Copy current live config, IDE settings, and repository inventory from this gMac into the repo.
# Delegates to scripts/audit_source.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$HERE/scripts/audit_source.sh" "$@"
