# doc_viewer_container

Generic **markdown documentation viewer** in a Podman container. Bakes in the repo `Docs/` folder at build time; at runtime you can mount any host folder to serve different content.

**Registry:** [quay.io/tmichett/docs-server](https://quay.io/repository/tmichett/docs-server)

## Quick start

```bash
cd Container
./manage-docs-server.sh build
./manage-docs-server.sh run
# → http://localhost:6780
```

Or develop without a container:

```bash
cd Container/docs-server
./dev-docs-server.sh
```

## Serve docs from a host folder

Mount any directory of markdown (subfolders become sidebar sections):

```bash
./manage-docs-server.sh run --docs-path ~/Github/RHCIVT_Tools/Docs
```

Add an extra section alongside baked-in docs:

```bash
./manage-docs-server.sh run --mount ~/my-notes:Notes
```

Change the host port (container always listens on **8080** internally):

```bash
./manage-docs-server.sh run --port 9090
DOCS_HOST_PORT=8888 ./manage-docs-server.sh run
```

## Push to Quay

```bash
cd Container/docs-server
./build-docs-server.sh build
./push-docs-server.sh
```

Image: `quay.io/tmichett/docs-server:latest`

Consumers:

```bash
cd Container
./manage-docs-server.sh pull
./manage-docs-server.sh run --docs-path /path/to/your/docs
```

## Features

- GitHub-style markdown rendering with light/dark/auto theme
- Searchable sidebar with auto-discovered sections
- Resizable sidebar and TOC anchor navigation
- Runtime doc mounts (`--docs-path`, `--mount`)
- Markdown Reader mascot in the header

## Repo layout

```
Docs/                          # Markdown baked into image (subdirs = nav sections)
  Dir1/
  Dir2/
Container/
  manage-docs-server.sh        # Main entry — run, build, pull, stop
  docs-server/
    Containerfile
    build-docs-server.sh
    push-docs-server.sh
    dev-docs-server.sh         # Local uv dev server
    docs_server/               # FastAPI app
    static/                    # CSS, JS, markdown-reader-logo.png
    templates/
```

## Docs folder structure

```
Docs/
  CourseA/
    README.md
    lab1.md
  CourseB/
    guide.md
```

Subdirectories become sidebar sections. A folder with only root-level `.md` files uses flat mode (no section grouping).

At runtime, `--docs-path` can point at any folder with the same layout.

## Environment

| Variable | Default | Purpose |
|----------|---------|---------|
| `VT_DOCS_ROOT` | `/docs` | Root path inside container |
| `VT_DOCS_SECTIONS` | `auto` | Comma list or `auto` (discover subdirs) |
| `VT_DOCS_TITLE` | `Document Viewer` | Browser title |
| `DOCS_HOST_PORT` | `6780` | Host port (`--port` or env) |
| `DOCS_IMAGE` | `localhost/docs-server:latest` | Local Podman image |
| `DOCS_QUAY_IMAGE` | `quay.io/tmichett/docs-server:latest` | Registry image |

Full variable list: [Container/docs-server/README.md](Container/docs-server/README.md#environment).

## Development

```bash
cd Container/docs-server
./dev-docs-server.sh                    # http://localhost:6780
./build-docs-server.sh run --live-mount # container with live Docs/ + UI assets
./build-docs-server.sh test
```
