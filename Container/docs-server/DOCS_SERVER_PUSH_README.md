# Docs Server — build and push

## Build

From repo root context (requires `Docs/` and `Container/docs-server/`):

```bash
./build-docs-server.sh build
```

Image: `localhost/docs-server:latest`

Only **`Docs/`** is copied into the image at `/docs/`. Each subdirectory becomes a navigation section.

## Run

```bash
# Baked-in Docs from image
./build-docs-server.sh run

# Host folder replaces /docs entirely
./build-docs-server.sh run --docs-path /path/to/markdown

# Add a section mount (path or path:SectionName)
./build-docs-server.sh run --mount ~/extra-docs:Extra

# Dev: live repo Docs + UI assets
./build-docs-server.sh run --live-mount
```

## Push to Quay

```bash
./push-docs-server.sh
```

| Setting | Default |
|---------|---------|
| Registry | `quay.io/tmichett/docs-server:latest` |
| `DOCS_QUAY_REPO` | `tmichett/docs-server` |

Create the repository on Quay first if it does not exist.

## Consumer pull/run

```bash
podman pull quay.io/tmichett/docs-server:latest

# Baked-in docs from image
Container/manage-docs-server.sh run

# Custom host docs folder
Container/manage-docs-server.sh run --docs-path /your/docs

# Custom port
Container/manage-docs-server.sh run --port 9090
```

Raw `podman run` (equivalent to `--docs-path`):

```bash
podman run -d --rm --name docs-server \
  -p 6780:8080 \
  -v /your/docs:/docs:ro \
  -e VT_DOCS_SECTIONS=auto \
  quay.io/tmichett/docs-server:latest
```

Open http://localhost:6780
