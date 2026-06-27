#!/usr/bin/env bash
# Run the docs server locally without a container (development).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

export VT_DOCS_ROOT="${VT_DOCS_ROOT:-$REPO_ROOT/Docs}"
export VT_DOCS_SECTIONS="${VT_DOCS_SECTIONS:-auto}"
export VT_DOCS_PORT="${VT_DOCS_PORT:-6780}"
export VT_DOCS_TITLE="${VT_DOCS_TITLE:-Document Viewer}"

cd "$SCRIPT_DIR"
uv sync
echo "[INFO] Serving markdown from $VT_DOCS_ROOT (sections: $VT_DOCS_SECTIONS)"
echo "[INFO] Open http://localhost:$VT_DOCS_PORT"
uv run python -m docs_server.app
