#!/usr/bin/env bash
# Build and manage the generic documentation viewer container.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONTAINERFILE="$SCRIPT_DIR/Containerfile"

LOCAL_IMAGE="${DOCS_IMAGE:-localhost/docs-server:latest}"
QUAY_IMAGE="${DOCS_QUAY_IMAGE:-quay.io/tmichett/docs-server:latest}"
CONTAINER_NAME="${DOCS_CONTAINER:-docs-server}"
HOST_PORT="${DOCS_HOST_PORT:-6780}"
CONTAINER_PORT=8080

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_podman() {
    if ! command -v podman &> /dev/null; then
        print_error "Podman is not installed."
        exit 1
    fi
    print_status "Podman version: $(podman --version)"
}

validate_build_context() {
    local missing=()
    [[ -f "$CONTAINERFILE" ]] || missing+=("$CONTAINERFILE")
    [[ -d "$REPO_ROOT/Docs" ]] || missing+=("Docs/")
    [[ -f "$SCRIPT_DIR/pyproject.toml" ]] || missing+=("Container/docs-server/pyproject.toml")
    if ((${#missing[@]} > 0)); then
        print_error "Missing build prerequisites:"
        for item in "${missing[@]}"; do
            print_error "  - $item"
        done
        exit 1
    fi
}

build_image() {
    local no_cache=false
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-cache) no_cache=true; shift ;;
            *) print_error "Unknown build option: $1"; exit 1 ;;
        esac
    done

    validate_build_context
    print_status "Building $LOCAL_IMAGE (Docs/ from repo root)"
    local -a build_args=(-f "$CONTAINERFILE" -t "$LOCAL_IMAGE" "$REPO_ROOT")
    if [[ "$no_cache" == true ]]; then
        build_args=(--no-cache "${build_args[@]}")
        print_status "Building without cache..."
    fi
    podman build "${build_args[@]}"
    print_success "Built $LOCAL_IMAGE"
    print_status "Size: $(podman images --format '{{.Size}}' "$LOCAL_IMAGE" | head -1)"
    echo ""
    print_status "Run:  $SCRIPT_DIR/build-docs-server.sh run"
    print_status "Push: $SCRIPT_DIR/push-docs-server.sh"
}

# Parse --mount SPEC where SPEC is /host/path or /host/path:SectionName
parse_mount_spec() {
    local spec="$1"
    MOUNT_SRC="${spec%%:*}"
    if [[ "$spec" == *:* ]]; then
        MOUNT_SECTION="${spec#*:}"
    else
        MOUNT_SECTION="$(basename "$MOUNT_SRC")"
    fi
}

validate_port() {
    if ! [[ "$HOST_PORT" =~ ^[0-9]+$ ]] || (( HOST_PORT < 1 || HOST_PORT > 65535 )); then
        print_error "Invalid port: $HOST_PORT (use 1-65535)"
        exit 1
    fi
}

run_container() {
    local docs_path=""
    local mount_extra=""
    local mount_live=false
    MOUNT_SRC=""
    MOUNT_SECTION=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--port)
                [[ $# -ge 2 ]] || { print_error "$1 requires a port number"; exit 1; }
                HOST_PORT="$2"
                shift 2
                ;;
            --docs-path)
                [[ $# -ge 2 ]] || { print_error "$1 requires a path"; exit 1; }
                docs_path="$2"
                shift 2
                ;;
            --mount)
                [[ $# -ge 2 ]] || { print_error "$1 requires PATH or PATH:SECTION"; exit 1; }
                mount_extra="$2"
                shift 2
                ;;
            --live-mount)
                mount_live=true
                shift
                ;;
            *)
                print_error "Unknown run option: $1"
                exit 1
                ;;
        esac
    done

    validate_port

    if ! podman image exists "$LOCAL_IMAGE" 2>/dev/null; then
        if podman image exists "$QUAY_IMAGE" 2>/dev/null; then
            print_status "Using registry image: $QUAY_IMAGE"
            LOCAL_IMAGE="$QUAY_IMAGE"
        else
            print_error "Build or pull an image first:"
            print_error "  $SCRIPT_DIR/build-docs-server.sh build"
            exit 1
        fi
    fi

    podman rm -f "$CONTAINER_NAME" 2>/dev/null || true

    local -a run_args=(
        -d --rm
        --name "$CONTAINER_NAME"
        --publish "${HOST_PORT}:${CONTAINER_PORT}"
        -e "VT_DOCS_ROOT=/docs"
        -e "VT_DOCS_SECTIONS=auto"
    )

    if [[ -n "$docs_path" ]]; then
        docs_path="$(cd "$docs_path" && pwd)"
        print_status "Docs root mount: ${docs_path} -> /docs"
        run_args+=(--volume "${docs_path}:/docs:ro")
    elif [[ "$mount_live" == true ]]; then
        print_status "Live mount: ${REPO_ROOT}/Docs -> /docs"
        run_args+=(
            --volume "$REPO_ROOT/Docs:/docs:ro"
            --volume "$SCRIPT_DIR/static:/app/static:ro"
            --volume "$SCRIPT_DIR/templates:/app/templates:ro"
        )
    fi

    if [[ -n "$mount_extra" ]]; then
        parse_mount_spec "$mount_extra"
        MOUNT_SRC="$(cd "$MOUNT_SRC" && pwd)"
        print_status "Extra section mount: ${MOUNT_SRC} -> /docs/${MOUNT_SECTION}"
        run_args+=(--volume "${MOUNT_SRC}:/docs/${MOUNT_SECTION}:ro")
    fi

    run_args+=("$LOCAL_IMAGE")
    print_status "Starting $CONTAINER_NAME on http://localhost:$HOST_PORT"
    podman run "${run_args[@]}"
    print_success "Open http://localhost:$HOST_PORT"
    print_status "Stop: $SCRIPT_DIR/build-docs-server.sh stop"
}

stop_container() {
    if podman ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        podman rm -f "$CONTAINER_NAME" 2>/dev/null || true
        print_success "Stopped and removed ${CONTAINER_NAME}"
    else
        print_warning "Container ${CONTAINER_NAME} is not running"
    fi
}

show_status() {
    echo ""
    print_status "Local image:  $LOCAL_IMAGE"
    print_status "Quay image:   $QUAY_IMAGE"
    print_status "Container:    $CONTAINER_NAME"
    print_status "Host port:    $HOST_PORT"
    echo ""
    podman images --filter "reference=$LOCAL_IMAGE" --format "  local  {{.Repository}}:{{.Tag}}  {{.Size}}" 2>/dev/null || echo "  local  (not built)"
    podman images --filter "reference=$QUAY_IMAGE" --format "  quay   {{.Repository}}:{{.Tag}}  {{.Size}}" 2>/dev/null || true
    echo ""
    if podman ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
        podman ps --filter "name=$CONTAINER_NAME" --format "  running  {{.Names}}  {{.Status}}  {{.Ports}}"
    else
        echo "  running  (not started)"
    fi
    echo ""
}

pull_image() {
    print_status "Pulling $QUAY_IMAGE"
    podman pull "$QUAY_IMAGE"
    podman tag "$QUAY_IMAGE" "$LOCAL_IMAGE"
    print_success "Tagged $QUAY_IMAGE -> $LOCAL_IMAGE"
}

run_tests() {
    print_status "Running unit tests..."
    (cd "$SCRIPT_DIR" && uv run python -m unittest test_docs_server.py -v)
}

show_usage() {
    local cmd="${DOCS_CLI_NAME:-$(basename "$0")}"
    cat <<EOF
Documentation viewer — build and run

Usage: ${cmd} <command> [options]

Commands:
  build [--no-cache]              Build local image ($LOCAL_IMAGE)
  run [options]                   Start container (default: http://localhost:$HOST_PORT)
  pull                            Pull $QUAY_IMAGE
  stop                            Stop and remove container
  status                          Show image/container status
  test                            Run unit tests
  help                            Show this help

Run options (use with \`run\`):
  -p, --port PORT                 Host port (default: 6780; container listens on 8080)
  --docs-path PATH                Mount host folder as /docs (replaces baked-in Docs)
  --mount PATH[:SECTION]          Add host folder as a section under /docs
  --live-mount                    Dev: mount repo Docs/ + UI assets from source

Environment:
  DOCS_HOST_PORT      Host port (same as --port; default: 6780)
  DOCS_IMAGE          Local image (default: localhost/docs-server:latest)
  DOCS_QUAY_IMAGE     Registry image (default: quay.io/tmichett/docs-server:latest)
  DOCS_CONTAINER      Container name (default: docs-server)

Examples:
  ${cmd} build
  ${cmd} run
  ${cmd} run --port 9090
  ${cmd} run -p 3000 --docs-path ~/Github/RHCIVT_Tools/Docs
  DOCS_HOST_PORT=8888 ${cmd} run
  ${cmd} run --docs-path ~/course-materials
  ${cmd} run --mount ~/extra-docs:CourseNotes
  ${cmd} run --live-mount
EOF
}

main() {
    case "${1:-build}" in
        help|-h|--help)
            show_usage
            exit 0
            ;;
    esac
    check_podman
    case "${1:-build}" in
        build) shift || true; build_image "$@" ;;
        run) shift || true; run_container "$@" ;;
        pull) pull_image ;;
        stop) stop_container ;;
        status) show_status ;;
        test) run_tests ;;
        help|-h|--help) show_usage ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"
