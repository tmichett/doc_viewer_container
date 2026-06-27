"""Documentation root and section configuration."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator


@dataclass(frozen=True)
class DocsConfig:
    root: Path
    sections: tuple[str, ...]

    @classmethod
    def from_env(cls) -> DocsConfig:
        root = Path(os.environ.get("VT_DOCS_ROOT", "/docs")).resolve()
        raw = os.environ.get("VT_DOCS_SECTIONS", "auto")
        if raw.strip().lower() in ("", "auto", "*"):
            sections = cls.discover_sections(root)
        else:
            sections = tuple(s.strip() for s in raw.split(",") if s.strip())
        return cls(root=root, sections=sections)

    @staticmethod
    def discover_sections(root: Path) -> tuple[str, ...]:
        """Find section subdirectories under root, or use flat mode for root-level .md."""
        if not root.is_dir():
            return ()
        sections: list[str] = []
        for child in sorted(root.iterdir()):
            if child.is_dir() and any(child.rglob("*.md")):
                sections.append(child.name)
        if not sections and any(root.glob("*.md")):
            return (".",)
        return tuple(sections)

    def validate(self) -> None:
        if not self.root.is_dir():
            raise SystemExit(f"Docs root not found: {self.root}")
        if not self.sections:
            raise SystemExit(
                f"No markdown sections found under {self.root}. "
                "Add subdirectories with .md files, or mount a docs folder at runtime."
            )
        if not any(self.section_dirs()):
            raise SystemExit(
                f"No doc sections found under {self.root} "
                f"(configured: {', '.join(self.sections)})"
            )

    def section_dirs(self) -> list[Path]:
        dirs: list[Path] = []
        for section in self.sections:
            if section == ".":
                dirs.append(self.root)
            else:
                path = self.root / section
                if path.is_dir():
                    dirs.append(path)
        return dirs

    def iter_markdown_files(self) -> Iterator[Path]:
        for section_dir in self.section_dirs():
            for path in sorted(section_dir.rglob("*.md")):
                if path.is_file():
                    yield path

    def resolve_doc(self, relative: str) -> Path:
        rel = Path(relative)
        if rel.is_absolute() or ".." in rel.parts:
            raise FileNotFoundError(relative)
        root = self.root.resolve()
        candidate = (root / rel).resolve()
        try:
            candidate.relative_to(root)
        except ValueError as exc:
            raise FileNotFoundError(relative) from exc
        if not candidate.is_file() or candidate.suffix.lower() != ".md":
            raise FileNotFoundError(relative)
        if "." in self.sections:
            return candidate
        section = candidate.relative_to(self.root).parts[0]
        if section not in self.sections:
            raise FileNotFoundError(relative)
        return candidate

    def github_url(self, doc_rel: str) -> str:
        base = os.environ.get("VT_DOCS_GITHUB_BASE", "").strip().rstrip("/")
        if not base:
            return "#"
        return f"{base}/{doc_rel}"
