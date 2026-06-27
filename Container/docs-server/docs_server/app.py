#!/usr/bin/env python3
"""FastAPI server for VT Tools markdown documentation."""

from __future__ import annotations

import os

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

from docs_server.markdown_render import render_markdown
from docs_server.nav import build_nav_tree, default_doc_path
from docs_server.paths import DocsConfig

CONFIG = DocsConfig.from_env()
PORT = int(os.environ.get("VT_DOCS_PORT", "8080"))
APP_TITLE = os.environ.get("VT_DOCS_TITLE", "Document Viewer")

PACKAGE_DIR = __import__("pathlib").Path(__file__).resolve().parent
STATIC_DIR = PACKAGE_DIR.parent / "static"
TEMPLATES = Jinja2Templates(directory=str(PACKAGE_DIR.parent / "templates"))


def _asset_version() -> str:
    """Cache-bust static assets when site.css/site.js change."""
    latest = 0
    for name in ("site.css", "site.js"):
        path = STATIC_DIR / name
        if path.is_file():
            latest = max(latest, int(path.stat().st_mtime))
    return str(latest or 1)

app = FastAPI(title=APP_TITLE, docs_url=None, redoc_url=None)
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")


@app.get("/", response_class=HTMLResponse)
async def home() -> RedirectResponse:
    default = default_doc_path(CONFIG)
    if not default:
        raise HTTPException(status_code=404, detail="No markdown files found")
    return RedirectResponse(url=f"/doc/{default}", status_code=302)


@app.get("/doc/{doc_path:path}", response_class=HTMLResponse)
async def view_doc(request: Request, doc_path: str) -> HTMLResponse:
    try:
        path = CONFIG.resolve_doc(doc_path)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail="Not found") from exc
    source = path.read_text(encoding="utf-8")
    rel = path.relative_to(CONFIG.root).as_posix()
    body_html = render_markdown(source, doc_path=path, docs_root=CONFIG.root)
    return TEMPLATES.TemplateResponse(
        request,
        "page.html",
        {
            "title": f"{path.stem} · {APP_TITLE}",
            "page_title": path.stem.replace("_", " "),
            "doc_path": rel,
            "github_url": CONFIG.github_url(rel),
            "body_html": body_html,
            "nav_tree": build_nav_tree(CONFIG),
            "app_title": APP_TITLE,
            "asset_version": _asset_version(),
        },
    )


@app.get("/health")
async def health() -> dict[str, str]:
    return {
        "status": "ok",
        "docs_root": str(CONFIG.root),
        "sections": ",".join(CONFIG.sections),
        "mode": "flat" if "." in CONFIG.sections else "sections",
    }


def main() -> None:
    import uvicorn

    CONFIG.validate()
    uvicorn.run(
        "docs_server.app:app",
        host=os.environ.get("VT_DOCS_HOST", "0.0.0.0"),
        port=PORT,
        reload=os.environ.get("VT_DOCS_RELOAD", "").lower() in ("1", "true", "yes"),
    )


if __name__ == "__main__":
    main()
