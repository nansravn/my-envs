#!/usr/bin/env bash
# Bootstrap a fresh Google corporate MacBook (gMac) to match the macbook-work environment.
# Delegates to scripts/apply_target.sh.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$HERE/scripts/apply_target.sh" "$@"
