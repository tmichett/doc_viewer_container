#!/usr/bin/env bash
# Run the RHCIVT Tools documentation viewer (wrapper — see build-docs-server.sh run).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/build-docs-server.sh" run "$@"
