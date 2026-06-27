"""Documentation navigation tree."""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from docs_server.paths import DocsConfig


@dataclass
class NavNode:
    name: str
    path: str | None = None
    children: list[NavNode] = field(default_factory=list)

    @property
    def is_dir(self) -> bool:
        return self.path is None and bool(self.children)


def build_nav_tree(config: DocsConfig) -> list[NavNode]:
    """Build a sorted tree from section directories under the docs root."""
    nodes: list[NavNode] = []
    for section_dir in config.section_dirs():
        section_name = section_dir.name if section_dir != config.root else "Docs"
        tree: dict[str, dict] = {}
        for md_path in sorted(section_dir.rglob("*.md")):
            if not md_path.is_file():
                continue
            rel = md_path.relative_to(config.root)
            parts = rel.parts
            cursor = tree
            if section_dir == config.root:
                dir_parts = parts[:-1]
            else:
                dir_parts = parts[1:-1]
            for part in dir_parts:
                cursor = cursor.setdefault(part, {})
            cursor[parts[-1]] = rel.as_posix()
        nodes.append(NavNode(name=section_name, children=_dict_to_nodes(tree)))
    return nodes


def _dict_to_nodes(data: dict) -> list[NavNode]:
    nodes: list[NavNode] = []
    for key in sorted(data.keys(), key=str.lower):
        value = data[key]
        if isinstance(value, dict):
            nodes.append(NavNode(name=key, children=_dict_to_nodes(value)))
        else:
            nodes.append(NavNode(name=key, path=value))
    return nodes


def default_doc_path(config: DocsConfig) -> str | None:
    """Prefer README or instructor guide, then first markdown file found."""
    preferred_suffixes = (
        "RHTLC_Instructor_Guide.md",
        "README.md",
    )
    for md in config.iter_markdown_files():
        for suffix in preferred_suffixes:
            if md.name == suffix or md.name.lower() == suffix.lower():
                return md.relative_to(config.root).as_posix()
    for md in config.iter_markdown_files():
        if md.name.upper() == "README.MD":
            return md.relative_to(config.root).as_posix()
    first = next(config.iter_markdown_files(), None)
    return first.relative_to(config.root).as_posix() if first else None
