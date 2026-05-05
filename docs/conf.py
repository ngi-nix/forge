#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
from datetime import date

extensions = [
    "myst_parser",
    "sphinx.ext.intersphinx",
    "sphinx.ext.todo",
    "sphinx_copybutton",
    "sphinx_design",
    "sphinx_sitemap",
    "notfound.extension",
]

myst_enable_extensions = [
    "colon_fence",
    "linkify",
    "tasklist",
    "attrs_block",
]

myst_heading_anchors = 3

myst_number_code_blocks = ["nix", "python"]

copybutton_prompt_text = r"\$ |nix-repl> "
copybutton_prompt_is_regexp = True

templates_path = ["_templates"]

source_suffix = ".md"

root_doc = "index"

project = "NGI Forge"
author = 'the <a href="https://nixos.org/community/teams/ngi/">Nix@NGI team</a>.'
copyright = "2026-" + str(date.today().year) + ", NixOS Foundation / Nix@NGI Team"

release = ""

suppress_warnings = [
    "ref.option",
]

todo_include_todos = True

pygments_style = "sphinx"

exclude_patterns = []

html_baseurl = "https://ngi-nix.github.io/forge/"

html_theme = "sphinx_book_theme"

html_theme_options = {
    "repository_url": "https://github.com/ngi-nix/forge",
    "repository_branch": "master",
    "path_to_docs": "docs",
    "use_repository_button": True,
    "show_navbar_depth": 2,
    "max_navbar_depth": 100,
}

html_title = "NGI Forge"
html_short_title = "NGI Forge"

html_static_path = ["_static"]

html_css_files = [
    "css/custom.css",
]

html_sidebars = {
    "**": [
        "search-button-field.html",
        "sbt-sidebar-nav.html",
    ],
}

html_search_language = "en"

sitemap_url_scheme = "{link}"

notfound_urls_prefix = "/"

man_pages = [
    (
        "manuals/user/index",
        "ngi-forge-user",
        "NGI Forge User Manual",
        "NGI Forge Contributors",
        5,
    ),
    (
        "manuals/contributor/index",
        "ngi-forge-contributor",
        "NGI Forge Contributor Manual",
        "NGI Forge Contributors",
        5,
    ),
]

intersphinx_mapping = {}

linkcheck_ignore = [
    r"https://matrix.to",
    r"https://github.com/.+/.+#.+$",
    r"https://github\.com/.+/.+/blob/.*#.*$",
    r"https://github\.com/.+/.+/tree/.*#.*$",
]

linkcheck_anchors_ignore = [
    r"^L(\d+)(-L\d+)?$",
]
