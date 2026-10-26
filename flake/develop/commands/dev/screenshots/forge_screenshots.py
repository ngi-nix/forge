"""forge-screenshots: update application screenshots.

For each application, find screenshot URLs, lock them with a hash, and write
them to a `screenshots.nix` file next to the recipe. Sources, in order:

1. AppStream metainfo files in the application packages. The packages are
   read from the local store or from a binary cache, without a build. If a
   package links desktop files or icons from other store paths (for example,
   a wrapper of an unwrapped package), the metainfo files of these store paths
   are also used.
2. AppStream metainfo files in the sources of the application packages. The
   sources are read from the local store or from a binary cache, or fetched.
3. AppStream metainfo files in the default branch of the Git repositories of
   these sources, for metainfo files that are not in a release yet.
4. Flathub, for the `screenshotSources.appstreamIds` option of the application,
   for the component IDs in the metainfo files, and for the desktop file IDs
   in reverse-DNS format.
5. Flathub, for the components found by a search for the name of the
   application, if the homepage or the source repository of the component is
   the same as a link of the application or of its packages.
6. The `screenshotSources.urls` option of the application.

If a source gives no image that can be fetched, the next source is used.
If a source before `screenshotSources.urls` gives screenshots, the command
tells you to remove `screenshotSources.urls`.

A URL of a file at a branch or a tag of a GitHub, GitLab or Forgejo repository
is changed to the URL of the file at the commit of the branch or the tag. Thus
the URL continues to work when the file changes or moves in the branch. If the
file at a new commit has the same hash, the URL keeps the old commit.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from collections.abc import Iterator
from functools import cache
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path, PurePosixPath

SUBSTITUTERS = ["https://cache.nixos.org", "https://ngi-forge.cachix.org"]
FLATHUB_API = "https://flathub.org/api/v2/appstream/"
FLATHUB_SEARCH = "https://flathub.org/api/v2/search"
# Search results to compare with the links of an application.
SEARCH_HITS = 5
# Flathub URLs that identify an application.
FLATHUB_LINKS = {"homepage": "homepage", "vcs_browser": "source repository"}
METAINFO_DIRS = ["share/metainfo", "share/appdata"]
# Wrappers often link these directories, or the files in them, from the
# wrapped package.
LINKED_DIRS = ["share/applications", "share/icons"]
METAINFO_SUFFIXES = (".metainfo.xml", ".appdata.xml")
# Directories in package sources that do not contain the metainfo file of the
# application.
SKIPPED_SOURCE_DIRS = {"node_modules", "test", "tests", "third_party", "vendor"}
XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"
# The web interface shows images with a maximum width of 1600 pixels.
FULL_WIDTH = 1600
USER_AGENT = "forge-screenshots (https://github.com/ngi-nix/forge)"

# Applied to the `apps` output of the flake.
EVAL_FILE = Path(__file__).with_name("eval.nix")


@dataclass
class Screenshot:
    url: str
    caption: str = ""
    default: bool = False
    hash: str = ""


def warn(message: str) -> None:
    print(f"warning: {message}", file=sys.stderr)


def notice(message: str) -> None:
    print(f"notice: {message}", file=sys.stderr)


def nix(*args: str) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(["nix", *args], capture_output=True)


class Store:
    """Read files from store paths in the local store or in a binary cache."""

    def __init__(self) -> None:
        self._location: dict[str, str | None] = {}
        # Keep the NARs that `nix store cat` downloads, for later reads.
        cache = Path(os.environ.get("XDG_CACHE_HOME") or Path.home() / ".cache")
        self._nar_cache = cache / "forge-screenshots" / "nar"
        self._nar_cache.mkdir(parents=True, exist_ok=True)

    def location(self, root: str) -> str | None:
        """Return "local", a substituter URL, or None if the path is not available."""
        if root not in self._location:
            if Path(root).exists():
                self._location[root] = "local"
            else:
                self._location[root] = next(
                    (
                        sub
                        for sub in SUBSTITUTERS
                        if nix("path-info", "--store", sub, root).returncode == 0
                    ),
                    None,
                )
        return self._location[root]

    @staticmethod
    def root(path: PurePosixPath) -> str:
        return str(PurePosixPath(*path.parts[:4]))

    def lstat(self, path: PurePosixPath) -> dict | None:
        location = self.location(self.root(path))
        if location is None:
            return None
        if location == "local":
            local = Path(path)
            if local.is_symlink():
                return {"type": "symlink", "target": os.readlink(local)}
            if local.is_dir():
                return {"type": "directory", "entries": sorted(os.listdir(local))}
            if local.is_file():
                return {"type": "regular"}
            return None
        result = nix("store", "ls", "--json", "--store", location, str(path))
        if result.returncode != 0:
            return None
        stat = json.loads(result.stdout)
        if stat["type"] == "directory":
            stat["entries"] = sorted(stat.get("entries", {}))
        return stat

    def resolve(self, path: str, depth: int = 0) -> tuple[PurePosixPath, dict] | None:
        """Follow the symlinks in each component of `path`."""
        parts = PurePosixPath(path).parts
        if depth > 16 or len(parts) < 4 or parts[:3] != ("/", "nix", "store"):
            return None
        current = PurePosixPath(*parts[:4])
        stat: dict | None = None
        for part in [None, *parts[4:]]:
            if part is not None:
                if stat is None or stat["type"] != "directory":
                    return None
                current = current / part
            stat = self.lstat(current)
            if stat is None:
                return None
            if stat["type"] == "symlink":
                target = PurePosixPath(stat["target"])
                if not target.is_absolute():
                    target = current.parent / target
                resolved = self.resolve(os.path.normpath(target), depth + 1)
                if resolved is None:
                    return None
                current, stat = resolved
        assert stat is not None
        return current, stat

    def fetch(self, root: str, drv: str) -> str | None:
        """Make sure that `root`, the output of the fixed-output derivation `drv`, is available."""
        if self.location(root) is None:
            result = nix("build", "--no-link", f"{drv}^out")
            if result.returncode != 0:
                warn(
                    f"cannot fetch `{root}`: {result.stderr.decode().strip().splitlines()[-1:]}"
                )
                return None
            self._location[root] = "local"
        return self.location(root)

    def walk(self, root: str) -> Iterator[PurePosixPath]:
        """Yield the regular files in `root`, except in `SKIPPED_SOURCE_DIRS` and hidden directories."""
        location = self.location(root)
        if location == "local":
            for directory, directories, files in os.walk(root):
                directories[:] = sorted(d for d in directories if not skipped(d))
                for name in sorted(files):
                    path = Path(directory, name)
                    if path.is_file() and not path.is_symlink():
                        yield PurePosixPath(path)
            return
        if location is None:
            return
        result = nix("store", "ls", "--recursive", "--json", "--store", location, root)
        if result.returncode != 0:
            return

        def visit(path: PurePosixPath, stat: dict) -> Iterator[PurePosixPath]:
            if stat["type"] == "regular":
                yield path
            elif stat["type"] == "directory":
                for name in sorted(stat.get("entries", {})):
                    if not skipped(name):
                        yield from visit(path / name, stat["entries"][name])

        yield from visit(PurePosixPath(root), json.loads(result.stdout))

    def read(self, path: PurePosixPath) -> bytes | None:
        location = self.location(self.root(path))
        if location == "local":
            return Path(path).read_bytes()
        if location is None:
            return None
        store = f"{location}?local-nar-cache={self._nar_cache}"
        result = nix("store", "cat", "--store", store, str(path))
        return result.stdout if result.returncode == 0 else None


def skipped(directory: str) -> bool:
    return directory.startswith(".") or directory in SKIPPED_SOURCE_DIRS


def linked_roots(store: Store, package: str) -> list[str]:
    """Return `package` and the store paths that its desktop files and icons link to."""
    roots = [package]
    for directory in LINKED_DIRS:
        path = PurePosixPath(package, directory)
        stat = store.lstat(path)
        if stat is None:
            continue
        if stat["type"] == "symlink":
            targets = [stat["target"]]
        elif stat["type"] == "directory":
            targets = [
                entry["target"]
                for entry in (store.lstat(path / name) for name in stat["entries"])
                if entry is not None and entry["type"] == "symlink"
            ]
        else:
            continue
        for target in targets:
            target_path = PurePosixPath(target)
            if target_path.is_absolute() and target_path.parts[:3] == (
                "/",
                "nix",
                "store",
            ):
                root = Store.root(target_path)
                if root not in roots:
                    roots.append(root)
    return roots


def desktop_ids(store: Store, package: str) -> list[str]:
    """Return the desktop file IDs of `package` that are in reverse-DNS format."""
    resolved = store.resolve(f"{package}/share/applications")
    if resolved is None or resolved[1]["type"] != "directory":
        return []
    return [
        name.removesuffix(".desktop")
        for name in resolved[1]["entries"]
        if re.fullmatch(r"[A-Za-z][\w-]*(\.[\w-]+){2,}\.desktop", name)
    ]


def metainfo_files(store: Store, package: str) -> Iterator[tuple[str, bytes]]:
    for directory in METAINFO_DIRS:
        resolved = store.resolve(f"{package}/{directory}")
        if resolved is None or resolved[1]["type"] != "directory":
            continue
        path, stat = resolved
        for name in stat["entries"]:
            if not name.endswith(".xml"):
                continue
            file = store.resolve(str(path / name))
            if file is not None and file[1]["type"] == "regular":
                data = store.read(file[0])
                if data is not None:
                    yield name, data


def source_metainfo_files(store: Store, source: dict) -> Iterator[tuple[str, bytes]]:
    if store.fetch(source["path"], source["drv"]) is None:
        return
    for path in store.walk(source["path"]):
        if path.name.endswith(METAINFO_SUFFIXES):
            data = store.read(path)
            if data is not None:
                yield str(path.relative_to(source["path"])), data


def git(*args: str) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(
        ["git", *args],
        capture_output=True,
        env={**os.environ, "GIT_TERMINAL_PROMPT": "0"},
        timeout=300,
    )


def upstream_metainfo_files(repo: str) -> Iterator[tuple[str, bytes]]:
    """Read the metainfo files in the default branch of the Git repository `repo`."""
    with tempfile.TemporaryDirectory(prefix="forge-screenshots-") as directory:
        # Get the file tree only. `git show` gets the contents of the metainfo files.
        clone = git(
            "clone",
            "--quiet",
            "--depth=1",
            "--filter=blob:none",
            "--no-checkout",
            repo,
            directory,
        )
        if clone.returncode != 0:
            warn(f"cannot clone {repo}: {clone.stderr.decode().strip()}")
            return
        tree = git("-C", directory, "ls-tree", "-r", "-z", "--name-only", "HEAD")
        for name in tree.stdout.decode().split("\0"):
            path = PurePosixPath(name)
            if not path.name.endswith(METAINFO_SUFFIXES) or any(
                skipped(part) for part in path.parent.parts
            ):
                continue
            show = git("-C", directory, "show", f"HEAD:{name}")
            if show.returncode == 0:
                yield name, show.stdout
            else:
                warn(f"cannot read `{name}` in {repo}: {show.stderr.decode().strip()}")


def text(element: ET.Element | None) -> str:
    return " ".join("".join(element.itertext()).split()) if element is not None else ""


def parse_metainfo(data: bytes) -> tuple[str, list[Screenshot]]:
    component = ET.fromstring(data)
    component_id = text(component.find("id"))
    screenshots = []
    for element in component.findall("screenshots/screenshot"):
        images = [i for i in element.findall("image") if XML_LANG not in i.attrib]
        sources = [i for i in images if i.get("type", "source") == "source"] or images
        if not sources:
            continue
        captions = [c for c in element.findall("caption") if XML_LANG not in c.attrib]
        screenshots.append(
            Screenshot(
                url=text(sources[0]),
                caption=text(captions[0]) if captions else "",
                default=element.get("type") == "default",
            )
        )
    # Show the default screenshot first.
    screenshots.sort(key=lambda s: not s.default)
    return component_id, screenshots


def flathub_get(request: urllib.request.Request, name: str) -> dict | None:
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)
    except urllib.error.HTTPError as e:
        if e.code != 404:
            warn(f"Flathub {name}: {e}")
    except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as e:
        warn(f"Flathub {name}: {e}")
    return None


@cache
def flathub_component(component_id: str) -> dict:
    request = urllib.request.Request(
        FLATHUB_API + urllib.parse.quote(component_id),
        headers={"User-Agent": USER_AGENT},
    )
    return flathub_get(request, f"`{component_id}`") or {}


def flathub_search(query: str) -> list[str]:
    """Return the IDs of the first Flathub components found for `query`."""
    request = urllib.request.Request(
        FLATHUB_SEARCH,
        data=json.dumps({"query": query}).encode(),
        headers={"User-Agent": USER_AGENT, "Content-Type": "application/json"},
    )
    hits = (flathub_get(request, f"search `{query}`") or {}).get("hits") or []
    return [hit["app_id"] for hit in hits[:SEARCH_HITS] if hit.get("app_id")]


def normalize_url(url: str) -> str:
    """Remove the parts of `url` that do not identify a web page."""
    parts = urllib.parse.urlsplit(url.strip().lower())
    return parts.netloc.removeprefix("www.") + parts.path.rstrip("/").removesuffix(
        ".git"
    )


def flathub_screenshots(component_id: str) -> list[Screenshot]:
    data = flathub_component(component_id)
    screenshots = []
    for element in data.get("screenshots") or []:
        sizes = sorted(element.get("sizes") or [], key=lambda s: int(s.get("width", 0)))
        if not sizes:
            continue
        size = next(
            (s for s in sizes if int(s.get("width", 0)) >= FULL_WIDTH), sizes[-1]
        )
        screenshots.append(
            Screenshot(
                url=size["src"],
                caption=" ".join((element.get("caption") or "").split()),
                default=bool(element.get("default")),
            )
        )
    screenshots.sort(key=lambda s: not s.default)
    return screenshots


def is_image(head: bytes) -> bool:
    return head.startswith((b"\x89PNG", b"\xff\xd8\xff", b"GIF8")) or (
        head[:4] == b"RIFF" and head[8:12] == b"WEBP"
    )


def prefetch(url: str) -> str | None:
    """Return the SRI hash of the image at `url`, or None if it is not an image."""
    result = nix(
        "store",
        "prefetch-file",
        "--json",
        "--hash-type",
        "sha256",
        "--name",
        "screenshot",
        url,
    )
    if result.returncode != 0:
        warn(f"cannot fetch {url}: {result.stderr.decode().strip().splitlines()[-1:]}")
        return None
    info = json.loads(result.stdout)
    with open(info["storePath"], "rb") as f:
        if not is_image(f.read(12)):
            warn(f"not a PNG, JPEG, GIF or WebP image: {url}")
            return None
    return info["hash"]


def parse(data: bytes, name: str, root: str) -> tuple[str, list[Screenshot]]:
    try:
        return parse_metainfo(data)
    except ET.ParseError as e:
        warn(f"cannot parse {name} in `{root}`: {e}")
        return "", []


HINTS = "`screenshotSources.urls`"


def candidates(
    name: str, app: dict, store: Store
) -> Iterator[tuple[str, list[Screenshot]]]:
    sources = app["screenshotSources"]
    component_ids = list(sources["appstreamIds"])
    desktop_component_ids = []
    roots: list[str] = []
    for package in dict.fromkeys(app["packages"]):
        if store.location(Store.root(PurePosixPath(package))) is None:
            warn(f"`{package}` is not in the local store or in a binary cache")
            continue
        roots += [root for root in linked_roots(store, package) if root not in roots]
        desktop_component_ids += desktop_ids(store, package)
    files = [
        (f"AppStream metainfo `{name}`", root, data)
        for root in roots
        for name, data in metainfo_files(store, root)
    ]
    found = False
    for source, root, data in files:
        component_id, screenshots = parse(data, source, root)
        if component_id and component_id not in component_ids:
            component_ids.append(component_id)
        if screenshots:
            found = True
            yield source, screenshots
    # Use the sources only if the packages do not install metainfo with screenshots.
    if not found:
        for package_source in app["sources"]:
            for name, data in source_metainfo_files(store, package_source):
                component_id, screenshots = parse(
                    data, f"`{name}`", package_source["path"]
                )
                if component_id and component_id not in component_ids:
                    component_ids.append(component_id)
                if screenshots:
                    found = True
                    yield f"AppStream metainfo `{name}` in the package source", screenshots
    # Use the default branch only if the released sources have no metainfo with screenshots.
    if not found:
        for repo in dict.fromkeys(app["repos"]):
            for name, data in upstream_metainfo_files(repo):
                component_id, screenshots = parse(data, f"`{name}`", repo)
                if component_id and component_id not in component_ids:
                    component_ids.append(component_id)
                if screenshots:
                    yield (
                        f"AppStream metainfo `{name}` in the default branch of {repo}",
                        screenshots,
                    )
    # Metainfo IDs often have a `.desktop` suffix that Flathub does not use.
    component_ids = [i.removesuffix(".desktop") for i in component_ids]
    component_ids += [i for i in desktop_component_ids if i not in component_ids]
    for component_id in dict.fromkeys(component_ids):
        yield f"Flathub `{component_id}`", flathub_screenshots(component_id)
    # Find other components with the same homepage or source repository as the application.
    links = {normalize_url(url) for url in app["links"] + app["repos"]}
    tried = set(component_ids)
    for query in dict.fromkeys([app["displayName"], name]):
        for component_id in flathub_search(query):
            if component_id in tried:
                continue
            tried.add(component_id)
            urls = flathub_component(component_id).get("urls") or {}
            same = [
                label
                for key, label in FLATHUB_LINKS.items()
                if urls.get(key) and normalize_url(urls[key]) in links
            ]
            if same:
                yield (
                    f"Flathub `{component_id}`, with the same {' and '.join(same)}",
                    flathub_screenshots(component_id),
                )
    yield HINTS, [
        Screenshot(url=item["url"], caption=item["caption"]) for item in sources["urls"]
    ]


REF = r"(?P<ref>refs/(?:heads|tags)/[^/]+|[^/]+)"
PATH = r"(?P<path>.+)"
# The URLs of a file at a branch or a tag: the URL pattern, the URL of the Git
# repository and the URL of the file at a commit. The first pattern that
# matches is used.
FORGE_FILE_URLS = [
    (
        re.compile(
            rf"https://raw\.githubusercontent\.com/(?P<repo>[^/]+/[^/]+)/{REF}/{PATH}"
        ),
        "https://github.com/{repo}.git",
        "https://raw.githubusercontent.com/{repo}/{commit}/{path}",
    ),
    # Files in Git LFS.
    (
        re.compile(
            rf"https://media\.githubusercontent\.com/media/(?P<repo>[^/]+/[^/]+)/{REF}/{PATH}"
        ),
        "https://github.com/{repo}.git",
        "https://media.githubusercontent.com/media/{repo}/{commit}/{path}",
    ),
    (
        re.compile(rf"https://github\.com/(?P<repo>[^/]+/[^/]+)/raw/{REF}/{PATH}"),
        "https://github.com/{repo}.git",
        "https://github.com/{repo}/raw/{commit}/{path}",
    ),
    # Forgejo and Gitea, for example Codeberg.
    (
        re.compile(
            rf"https://(?P<host>[^/]+)/(?P<repo>[^/]+/[^/]+)/raw/(?:branch|tag|commit)/{REF}/{PATH}"
        ),
        "https://{host}/{repo}.git",
        "https://{host}/{repo}/raw/commit/{commit}/{path}",
    ),
    (
        re.compile(rf"https://(?P<host>[^/]+)/(?P<repo>.+?)/-/raw/{REF}/{PATH}"),
        "https://{host}/{repo}.git",
        "https://{host}/{repo}/-/raw/{commit}/{path}",
    ),
    # Old GitLab URLs, without `-/`.
    (
        re.compile(rf"https://(?P<host>gitlab\.[^/]+)/(?P<repo>.+?)/raw/{REF}/{PATH}"),
        "https://{host}/{repo}.git",
        "https://{host}/{repo}/-/raw/{commit}/{path}",
    ),
]
COMMIT = re.compile(r"[0-9a-f]{40}|[0-9a-f]{64}")


def forge_file(url: str) -> tuple[int, dict[str, str]] | None:
    """Return the index in `FORGE_FILE_URLS` and the parts of the URL `url`."""
    for index, (pattern, _, _) in enumerate(FORGE_FILE_URLS):
        match = pattern.fullmatch(url)
        if match:
            return index, match.groupdict()
    return None


@cache
def commit_of(repo: str, ref: str) -> str | None:
    """Return the commit of the branch or the tag `ref` in the Git repository `repo`."""
    if COMMIT.fullmatch(ref):
        return ref
    names = (
        [ref] if ref.startswith("refs/") else [f"refs/heads/{ref}", f"refs/tags/{ref}"]
    )
    # `<tag>^{}` gives the commit of an annotated tag.
    peeled = [f"{name}^{{}}" for name in names if name.startswith("refs/tags/")]
    result = git("ls-remote", repo, *names, *peeled)
    if result.returncode != 0:
        warn(f"cannot read the references of {repo}: {result.stderr.decode().strip()}")
        return None
    commits = {
        name: commit
        for commit, name in (
            line.split("\t") for line in result.stdout.decode().splitlines()
        )
    }
    for name in names:
        commit = commits.get(f"{name}^{{}}") or commits.get(name)
        if commit:
            return commit
    warn(f"cannot find the branch or tag `{ref}` in {repo}")
    return None


def pinned(url: str) -> str:
    """Return the URL of the file `url` at the commit of its branch or tag."""
    file = forge_file(url)
    if not file:
        return url
    index, parts = file
    _, repo, template = FORGE_FILE_URLS[index]
    commit = commit_of(repo.format(**parts), parts["ref"])
    return template.format(**parts, commit=commit) if commit else url


def same_file(old: str, new: str) -> bool:
    """Whether the URL `old` is the file of the URL `new` at a commit."""
    old_file, new_file = forge_file(old), forge_file(new)
    if not old_file or not new_file or not COMMIT.fullmatch(old_file[1]["ref"]):
        return False

    def location(file: tuple[int, dict[str, str]]) -> tuple[str, str]:
        index, parts = file
        return FORGE_FILE_URLS[index][1].format(**parts), parts["path"]

    return location(old_file) == location(new_file)


def lock(screenshots: list[Screenshot], maximum: int) -> list[Screenshot]:
    locked = []
    for screenshot in screenshots:
        if len(locked) >= maximum:
            break
        if not screenshot.url.startswith("https://"):
            warn(f"not an HTTPS URL: {screenshot.url}")
            continue
        url = pinned(screenshot.url)
        if url != screenshot.url:
            screenshot.hash = prefetch(url) or ""
            if screenshot.hash:
                screenshot.url = url
        if not screenshot.hash:
            screenshot.hash = prefetch(screenshot.url) or ""
        if screenshot.hash:
            locked.append(screenshot)
    return locked


def nix_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("${", "\\${")
    return f'"{escaped}"'


def nix_attr(name: str) -> str:
    return name if re.fullmatch(r"[a-zA-Z_][a-zA-Z0-9_'-]*", name) else nix_string(name)


def render(name: str, source: str, screenshots: list[Screenshot]) -> str:
    lines = [
        "# Generated by `forge-screenshots`. Do not edit.",
        f"# Source: {source}.",
        f"# To override, set `apps.{name}.screenshots` in `recipe.nix`.",
        "{ lib, ... }:",
        "{",
        f"  apps.{nix_attr(name)}.screenshots = lib.mkDefault [",
    ]
    for screenshot in screenshots:
        lines += [
            "    {",
            f"      url = {nix_string(screenshot.url)};",
            f"      hash = {nix_string(screenshot.hash)};",
        ]
        if screenshot.caption:
            lines.append(f"      caption = {nix_string(screenshot.caption)};")
        lines.append("    }")
    lines += ["  ];", "}", ""]
    return "\n".join(lines)


LOCKED_URL = re.compile(r'url = "([^"]*)";\s*hash = "([^"]*)";')


def keep_commits(screenshots: list[Screenshot], old: str) -> None:
    """Keep the URLs in the file `old` of the files that have the same hash.

    Thus a new commit in a branch does not change the file, if the screenshots
    do not change.
    """
    old_urls = {hash: url for url, hash in LOCKED_URL.findall(old)}
    for screenshot in screenshots:
        old_url = old_urls.get(screenshot.hash)
        if old_url and same_file(old_url, screenshot.url):
            screenshot.url = old_url


SOURCE_LINE = re.compile(r"^# Source: .*\n", re.M)
METAINFO_NAME = re.compile(r"AppStream metainfo `(?:[^`]*/)?([^`/]+)`")


def same_metainfo(old: str, source: str) -> bool:
    """Whether `old` has the same screenshots from the same metainfo file name.

    The package, its source and the default branch of its repository often have
    the same metainfo file. If the package is not available, the source changes,
    but the screenshots do not change. Thus, do not change the file.
    """
    line = SOURCE_LINE.search(old)
    old_name = line and METAINFO_NAME.search(line.group())
    new_name = METAINFO_NAME.search(source)
    return bool(old_name and new_name and old_name[1] == new_name[1])


def update(
    name: str, app: dict, store: Store, root: Path, args: argparse.Namespace
) -> str:
    for source, screenshots in candidates(name, app, store):
        locked = lock(screenshots, args.max)
        if not locked:
            continue
        if source != HINTS and app["screenshotSources"]["urls"]:
            notice(
                f"`apps.{name}.screenshotSources.urls` is not used,"
                f" because {source} has screenshots. Remove it."
            )
        target = root / Path(app["recipePath"]).parent / "screenshots.nix"
        existing = target.read_text() if target.exists() else ""
        keep_commits(locked, existing)
        content = render(name, source, locked)
        if existing:
            if existing == content or (
                SOURCE_LINE.sub("", existing) == SOURCE_LINE.sub("", content)
                and same_metainfo(existing, source)
            ):
                return f"unchanged ({source})"
        if args.dry_run:
            return f"would update ({source})"
        target.write_text(content)
        subprocess.run(["nixfmt", str(target)], check=False)
        return f"updated ({source})"
    return "no screenshots found"


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="forge-screenshots", description=__doc__.split("\n")[0]
    )
    parser.add_argument("apps", nargs="*", help="applications to update (default: all)")
    parser.add_argument("--flake", default=".", help="flake to evaluate (default: .)")
    parser.add_argument(
        "--max", type=int, default=6, help="maximum screenshots per app (default: 6)"
    )
    parser.add_argument(
        "--jobs", type=int, default=8, help="applications to update in parallel"
    )
    parser.add_argument("--dry-run", action="store_true", help="do not write files")
    args = parser.parse_args()

    root = Path(
        subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
    )
    result = nix(
        "eval", "--json", f"{args.flake}#apps", "--apply", EVAL_FILE.read_text()
    )
    if result.returncode != 0:
        sys.exit(result.stderr.decode())
    apps: dict[str, dict] = json.loads(result.stdout)
    unknown = [name for name in args.apps if name not in apps]
    if unknown:
        sys.exit(f"unknown applications: {', '.join(unknown)}")
    names = args.apps or sorted(apps)

    store = Store()
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        results = executor.map(
            lambda name: update(name, apps[name], store, root, args), names
        )
        for name, outcome in zip(names, results):
            print(f"{name}: {outcome}")


if __name__ == "__main__":
    main()
