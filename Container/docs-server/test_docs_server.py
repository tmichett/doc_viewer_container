#!/usr/bin/env python3
"""Tests for docs-server."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from docs_server.markdown_render import render_markdown
from docs_server.nav import build_nav_tree, default_doc_path
from docs_server.paths import DocsConfig


class DocsServerTests(unittest.TestCase):
    REPO = Path(__file__).resolve().parent.parent.parent

    @classmethod
    def setUpClass(cls) -> None:
        cls.docs_root = cls.REPO / "Docs"
        cls.config = DocsConfig(root=cls.docs_root, sections=DocsConfig.discover_sections(cls.docs_root))

    def test_discover_sections(self) -> None:
        self.assertIn("Dir1", self.config.sections)
        self.assertIn("Dir2", self.config.sections)

    def test_default_doc_exists(self) -> None:
        path = default_doc_path(self.config)
        self.assertIsNotNone(path)
        self.assertTrue((self.config.root / path).is_file())

    def test_nav_tree_has_sections(self) -> None:
        tree = build_nav_tree(self.config)
        names = {node.name for node in tree}
        self.assertIn("Dir1", names)
        self.assertIn("Dir2", names)

    def test_rewrites_relative_md_links(self) -> None:
        html = render_markdown(
            "See [readme](README.md).",
            doc_path=self.config.root / "Dir1/README.md",
            docs_root=self.config.root,
        )
        self.assertIn('href="/doc/Dir1/README.md"', html)

    def test_heading_anchors_match_toc_links(self) -> None:
        html = render_markdown(
            "## Troubleshooting\n\nSee [fix](#troubleshooting).",
            doc_path=self.config.root / "Dir1/README.md",
            docs_root=self.config.root,
        )
        self.assertIn('id="troubleshooting"', html)
        self.assertIn('href="#troubleshooting"', html)

    def test_resolve_doc_in_section(self) -> None:
        path = self.config.resolve_doc("Dir2/RHTLC_Instructor_Guide.md")
        self.assertTrue(path.is_file())

    def test_flat_mode_discovery(self) -> None:
        import tempfile

        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "guide.md").write_text("# Guide\n", encoding="utf-8")
            sections = DocsConfig.discover_sections(root)
            self.assertEqual(sections, (".",))
            cfg = DocsConfig(root=root, sections=sections)
            self.assertTrue(cfg.resolve_doc("guide.md").is_file())


if __name__ == "__main__":
    unittest.main()
