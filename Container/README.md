# Container

Scripts to build, run, and push the documentation viewer.

## Main entry

```bash
./manage-docs-server.sh <command> [options]
```

| Command | Description |
|---------|-------------|
| `build [--no-cache]` | Build local image (`localhost/docs-server:latest`) |
| `run [options]` | Start on http://localhost:6780 (container :8080) |
| `pull` | Pull `quay.io/tmichett/docs-server:latest` |
| `stop` | Stop and remove container |
| `status` | Show image/container status |
| `test` | Run unit tests |
| `help` | Show usage |

### Common run examples

```bash
./manage-docs-server.sh run
./manage-docs-server.sh run --port 9090
./manage-docs-server.sh run --docs-path ~/Github/RHCIVT_Tools/Docs
./manage-docs-server.sh run --mount ~/extra-docs:CourseNotes
./manage-docs-server.sh run --live-mount
DOCS_HOST_PORT=8888 ./manage-docs-server.sh run
```

## Scripts

| Script | Purpose |
|--------|---------|
| `manage-docs-server.sh` | Wrapper — preferred entry for run/pull/stop |
| `docs-server/build-docs-server.sh` | Build, run, test (invoked by manage script) |
| `docs-server/push-docs-server.sh` | Tag and push to Quay |
| `docs-server/dev-docs-server.sh` | Local uv dev server (no Podman) |

## More documentation

- [../README.md](../README.md) — repo overview and layout
- [docs-server/README.md](docs-server/README.md) — app features, env vars, dev workflow
- [docs-server/DOCS_SERVER_PUSH_README.md](docs-server/DOCS_SERVER_PUSH_README.md) — Quay push/pull
