"""GitHub-flavored markdown rendering."""

from __future__ import annotations

import re
from pathlib import Path
from urllib.parse import quote

from markdown_it import MarkdownIt
from mdit_py_plugins.anchors import anchors_plugin
from mdit_py_plugins.footnote import footnote_plugin
from mdit_py_plugins.tasklists import tasklists_plugin

_MD = (
    MarkdownIt("commonmark", {"linkify": True, "html": True})
    .enable("table")
    .use(tasklists_plugin)
    .use(footnote_plugin)
    .use(anchors_plugin, min_level=1, max_level=6)
)

_REL_MD_LINK = re.compile(
    r'(<a\s+href=")([^"#:?]+?\.md(?:#[^"]*)?)(")',
    re.IGNORECASE,
)


def render_markdown(text: str, *, doc_path: Path, docs_root: Path) -> str:
    """Render markdown to HTML and rewrite relative .md links for the doc viewer."""
    html = _MD.render(text)
    return _rewrite_md_links(html, doc_path=doc_path, docs_root=docs_root)


def _rewrite_md_links(html: str, *, doc_path: Path, docs_root: Path) -> str:
    doc_dir = doc_path.parent

    def repl(match: re.Match[str]) -> str:
        href = match.group(2)
        path_part, fragment = (href.split("#", 1) + [""])[:2]
        if path_part.startswith(("/doc/", "http://", "https://", "mailto:")):
            return match.group(0)
        target = (doc_dir / path_part).resolve()
        try:
            target.relative_to(docs_root.resolve())
        except ValueError:
            return match.group(0)
        rel = target.relative_to(docs_root.resolve()).as_posix()
        url = f"/doc/{quote(rel, safe='/')}"
        if fragment:
            url = f"{url}#{fragment}"
        return f'{match.group(1)}{url}{match.group(3)}'

    return _REL_MD_LINK.sub(repl, html)
