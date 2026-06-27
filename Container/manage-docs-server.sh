#!/usr/bin/env bash
# Pull docs-server from Quay and run (wrapper around docs-server/build-docs-server.sh).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOCS_CLI_NAME="$(basename "$0")"
exec "$SCRIPT_DIR/docs-server/build-docs-server.sh" "$@"
