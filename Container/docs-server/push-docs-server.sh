#!/usr/bin/env bash
# Tag and push the documentation viewer to quay.io/tmichett/docs-server
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_IMAGE="${DOCS_IMAGE:-localhost/docs-server:latest}"
REGISTRY="quay.io"
REMOTE_REPO="${DOCS_QUAY_REPO:-tmichett/docs-server}"
REMOTE_TAG="${DOCS_QUAY_TAG:-latest}"
REMOTE_IMAGE="${DOCS_QUAY_IMAGE:-$REGISTRY/$REMOTE_REPO:$REMOTE_TAG}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_podman() {
    command -v podman &>/dev/null || { print_error "Podman is not installed."; exit 1; }
    print_status "Podman version: $(podman --version)"
}

check_local_image() {
    if ! podman image exists "$LOCAL_IMAGE" 2>/dev/null; then
        print_error "Local image not found: $LOCAL_IMAGE"
        print_error "Build first: $SCRIPT_DIR/build-docs-server.sh build"
        exit 1
    fi
    print_success "Local image: $(podman images --filter reference="$LOCAL_IMAGE" --format '{{.Repository}}:{{.Tag}} ({{.Size}})')"
}

perform_login() {
    print_status "Logging into $REGISTRY..."
    podman login "$REGISTRY"
}

show_usage() {
    cat <<EOF
Push docs-server image to Quay.io

Usage: $(basename "$0") [--dry-run] [--no-cleanup]

Target: $REMOTE_IMAGE

Environment:
  DOCS_IMAGE        Local source image (default: localhost/docs-server:latest)
  DOCS_QUAY_REPO    Quay repo path (default: tmichett/docs-server)
  DOCS_QUAY_TAG     Tag (default: latest)
  DOCS_QUAY_IMAGE   Full remote reference (overrides repo:tag)
EOF
}

main() {
    local cleanup=true dry_run=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) show_usage; exit 0 ;;
            --no-cleanup) cleanup=false; shift ;;
            --dry-run) dry_run=true; shift ;;
            *) print_error "Unknown option: $1"; exit 1 ;;
        esac
    done

    print_status "Target: $REMOTE_IMAGE"
    check_podman
    check_local_image

    if [[ "$dry_run" == true ]]; then
        print_status "[dry-run] Would push $REMOTE_IMAGE"
        exit 0
    fi

    perform_login
    podman tag "$LOCAL_IMAGE" "$REMOTE_IMAGE"
    podman push "$REMOTE_IMAGE"
    print_success "Pushed $REMOTE_IMAGE"
    echo ""
    echo "Pull and run:"
    echo "  podman pull $REMOTE_IMAGE"
    echo "  DOCS_QUAY_IMAGE=$REMOTE_IMAGE $SCRIPT_DIR/build-docs-server.sh run"
    echo "  DOCS_QUAY_IMAGE=$REMOTE_IMAGE $SCRIPT_DIR/build-docs-server.sh run --docs-path /path/to/docs"

    if [[ "$cleanup" == true ]]; then
        podman rmi "$REMOTE_IMAGE" 2>/dev/null || true
    fi
}

main "$@"
