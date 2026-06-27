# Docs Server

FastAPI web viewer for markdown documentation. Renders pages with GitHub Markdown CSS (light/dark), a searchable sidebar, resizable nav, and in-page TOC anchor links.

Bakes in the repo **`Docs/`** folder at build time. At runtime, mount any host folder to replace or extend content.

**Registry:** [quay.io/tmichett/docs-server](https://quay.io/repository/tmichett/docs-server)

## Quick start (local dev)

```bash
cd Container/docs-server
./dev-docs-server.sh
```

Open **http://localhost:6780** — sections are auto-discovered from subfolders under `Docs/`.

## Quick start (container)

```bash
cd Container/docs-server
./build-docs-server.sh build
./build-docs-server.sh run
# → http://localhost:6780
```

Or use the wrapper from `Container/`:

```bash
cd Container
./manage-docs-server.sh run
./manage-docs-server.sh run --port 9090
./manage-docs-server.sh help
```

## Serve docs from a host folder

Replace baked-in docs entirely:

```bash
./manage-docs-server.sh run --docs-path ~/Github/RHCIVT_Tools/Docs
```

Add an extra section alongside baked-in docs:

```bash
./manage-docs-server.sh run --mount ~/my-notes:Notes
```

## Dark mode

Click the **◐** button in the header. Cycles **auto → light → dark → auto**. Preference is saved in `localStorage`.

## Build script commands

| Command | Description |
|---------|-------------|
| `build [--no-cache]` | Build `localhost/docs-server:latest` |
| `run [options]` | Start container (default http://localhost:6780) |
| `pull` | Pull `quay.io/tmichett/docs-server:latest` |
| `stop` | Stop and remove container |
| `status` | Image + container status |
| `test` | Unit tests |
| `help` | Show usage |

### Run options

| Option | Description |
|--------|-------------|
| `-p`, `--port PORT` | Host port (default **6780**; container listens on **8080**) |
| `--docs-path PATH` | Mount host folder as `/docs` (replaces baked-in `Docs/`) |
| `--mount PATH[:SECTION]` | Add host folder as a section under `/docs` |
| `--live-mount` | Dev: mount repo `Docs/` + UI assets (`static/`, `templates/`) from source |

Examples:

```bash
./build-docs-server.sh run --port 9090
./build-docs-server.sh run -p 3000 --docs-path ~/course-materials
DOCS_HOST_PORT=8888 ./build-docs-server.sh run
./build-docs-server.sh run --live-mount
```

## Push to Quay

```bash
./build-docs-server.sh build
./push-docs-server.sh
```

See [DOCS_SERVER_PUSH_README.md](DOCS_SERVER_PUSH_README.md) for registry details.

Consumers:

```bash
cd Container
./manage-docs-server.sh pull
./manage-docs-server.sh run --docs-path /path/to/your/docs
```

## Environment

### Container runtime (`VT_DOCS_*`)

| Variable | Default | Description |
|----------|---------|-------------|
| `VT_DOCS_ROOT` | `/docs` | Root path inside container (or repo `Docs/` in dev) |
| `VT_DOCS_SECTIONS` | `auto` | Comma-separated section dirs, or `auto` to discover subdirs |
| `VT_DOCS_PORT` | `8080` (container) / `6780` (dev) | App listen port |
| `VT_DOCS_TITLE` | `Document Viewer` | Browser title and header |
| `VT_DOCS_GITHUB_BASE` | *(empty)* | Prefix for “View on GitHub” links |
| `VT_DOCS_HOST` | `0.0.0.0` | Bind address |
| `VT_DOCS_RELOAD` | *(empty)* | Set `true` for uvicorn reload (dev) |

### Podman scripts (`DOCS_*`)

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCS_HOST_PORT` | `6780` | Host port (same as `--port`) |
| `DOCS_IMAGE` | `localhost/docs-server:latest` | Local image name |
| `DOCS_QUAY_IMAGE` | `quay.io/tmichett/docs-server:latest` | Registry image for pull/run |
| `DOCS_CONTAINER` | `docs-server` | Container name |
| `DOCS_QUAY_REPO` | `tmichett/docs-server` | Quay repo path (push script) |
| `DOCS_QUAY_TAG` | `latest` | Image tag (push script) |
| `DOCS_CLI_NAME` | *(script basename)* | Display name in help text |

## Features

- GitHub-style markdown (tables, task lists, footnotes, linkify)
- Auto-discovered sidebar sections from `Docs/` subfolders (or flat mode for root-level `.md` only)
- Filter/search box in the sidebar
- Resizable sidebar (drag splitter; width saved in `localStorage`)
- TOC anchor links (GitHub-compatible heading IDs)
- Relative `.md` links rewritten for in-site navigation
- Manual dark/light/auto theme toggle
- Markdown Reader mascot logo in sticky header

## Docs folder structure

Place markdown under `Docs/` with one subdirectory per section:

```
Docs/
  Dir1/
    README.md
  Dir2/
    RHTLC_Instructor_Guide.md
```

At runtime, `--docs-path` can point at any folder with the same layout (or flat `.md` files at the top level).

## Rebuild after changes

**Docs content** (when not using live mount or `--docs-path`):

```bash
./build-docs-server.sh build && ./build-docs-server.sh run
```

**UI assets** (`static/`, `templates/`) — rebuild the image, or use live mount:

```bash
./build-docs-server.sh run --live-mount
```

After pushing a new image to Quay:

```bash
./push-docs-server.sh
```

## Tests

```bash
./build-docs-server.sh test
# or
uv run python -m unittest test_docs_server.py -v
```
