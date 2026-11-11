"""forge-screenshots: update application screenshots.

For each application, find screenshot URLs, lock them with a hash, and write
them to a `screenshots.nix` file next to the recipe. A `screenshots.nix` file
that this command did not write stays as it is. Sources, in order:

1. AppStream metainfo files in the application packages. The packages are
   read from the local store or from a binary cache, without a build. If a
   package links desktop files or icons from other store paths (for example,
   a wrapper of an unwrapped package), the metainfo files of these store paths
   are also used.
2. AppStream metainfo files in the sources of the application packages. The
   sources are read from the local store or from a binary cache, or fetched
   with Nix.

If a source gives no image that can be fetched, the next source is used.

With `--check`, the command does not write files. It downloads each screenshot
URL with a hash in the final configuration of the applications, also the
screenshots that a recipe sets by hand. It tells you which URLs cannot be
fetched or have a different hash, and exits with status 1 if there are any.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import threading
import xml.etree.ElementTree as ET
from collections.abc import Iterator
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path, PurePosixPath

SUBSTITUTERS = ["https://cache.nixos.org", "https://ngi-forge.cachix.org"]
METAINFO_DIRS = ["share/metainfo", "share/appdata"]
# Wrappers often link these directories, or the files in them, from the
# wrapped package.
LINKED_DIRS = ["share/applications", "share/icons"]
METAINFO_SUFFIXES = (".metainfo.xml", ".appdata.xml")
# Directories in package sources that do not contain the metainfo file of the
# application.
SKIPPED_SOURCE_DIRS = {"node_modules", "test", "tests", "third_party", "vendor"}
XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"

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


VERBOSE = False
# The application that the current thread updates or checks, for `info`.
_current = threading.local()


def info(message: str) -> None:
    if VERBOSE:
        print(f"{getattr(_current, 'app', '')}: {message}", file=sys.stderr)


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
    info(f"reading source `{source['path']}`")
    if store.fetch(source["path"], source["drv"]) is None:
        return
    for path in store.walk(source["path"]):
        if path.name.endswith(METAINFO_SUFFIXES):
            data = store.read(path)
            if data is not None:
                yield str(path.relative_to(source["path"])), data


def text(element: ET.Element | None) -> str:
    return " ".join("".join(element.itertext()).split()) if element is not None else ""


def parse_metainfo(data: bytes) -> list[Screenshot]:
    component = ET.fromstring(data)
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


def parse(data: bytes, name: str, root: str) -> list[Screenshot]:
    try:
        return parse_metainfo(data)
    except ET.ParseError as e:
        warn(f"cannot parse {name} in `{root}`: {e}")
        return []


def candidates(
    name: str, app: dict, store: Store
) -> Iterator[tuple[str, list[Screenshot]]]:
    roots: list[str] = []
    for package in dict.fromkeys(app["packages"]):
        location = store.location(Store.root(PurePosixPath(package)))
        if location is None:
            warn(f"`{package}` is not in the local store or in a binary cache")
            continue
        info(f"`{package}`: {location}")
        for root in linked_roots(store, package):
            if root not in roots:
                if root != package:
                    info(f"`{package}` links to `{root}`")
                roots.append(root)
    files = [
        (f"AppStream metainfo `{name}`", root, data)
        for root in roots
        for name, data in metainfo_files(store, root)
    ]
    found = False
    for source, root, data in files:
        screenshots = parse(data, source, root)
        info(f"{source} in `{root}`: {len(screenshots)} screenshots")
        if screenshots:
            found = True
            yield source, screenshots
    # Use the sources only if the packages do not install metainfo with screenshots.
    if not found:
        info(
            "no metainfo with screenshots in the packages, checking the package sources"
        )
        for package_source in app["sources"]:
            for name, data in source_metainfo_files(store, package_source):
                screenshots = parse(data, f"`{name}`", package_source["path"])
                info(f"`{name}` in the package source: {len(screenshots)} screenshots")
                if screenshots:
                    yield f"AppStream metainfo `{name}` in the package source", screenshots


def lock(screenshots: list[Screenshot], maximum: int) -> list[Screenshot]:
    locked = []
    for screenshot in screenshots:
        if len(locked) >= maximum:
            break
        if not screenshot.url.startswith("https://"):
            warn(f"not an HTTPS URL: {screenshot.url}")
            continue
        screenshot.hash = prefetch(screenshot.url) or ""
        if screenshot.hash:
            info(f"{screenshot.url}: {screenshot.hash}")
            locked.append(screenshot)
        else:
            info(f"{screenshot.url}: skipped")
    return locked


def nix_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("${", "\\${")
    return f'"{escaped}"'


def nix_attr(name: str) -> str:
    return name if re.fullmatch(r"[a-zA-Z_][a-zA-Z0-9_'-]*", name) else nix_string(name)


GENERATED = "# Generated by `forge-screenshots`."


def render(name: str, source: str, screenshots: list[Screenshot]) -> str:
    lines = [
        f"{GENERATED} Do not edit.",
        f"# Source: {source}.",
        "# To set the screenshots manually, replace this file.",
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


SOURCE_LINE = re.compile(r"^# Source: .*\n", re.M)
METAINFO_NAME = re.compile(r"AppStream metainfo `(?:[^`]*/)?([^`/]+)`")


def same_metainfo(old: str, source: str) -> bool:
    """Whether `old` has the same screenshots from the same metainfo file name.

    The package and its source often have the same metainfo file. If the
    package is not available, the source changes, but the screenshots do not
    change. Thus, do not change the file.
    """
    line = SOURCE_LINE.search(old)
    old_name = line and METAINFO_NAME.search(line.group())
    new_name = METAINFO_NAME.search(source)
    return bool(old_name and new_name and old_name[1] == new_name[1])


def update(
    name: str, app: dict, store: Store, root: Path, args: argparse.Namespace
) -> str:
    _current.app = name
    target = root / Path(app["recipePath"]).parent / "screenshots.nix"
    info(f"`{target.relative_to(root)}`")
    existing = target.read_text() if target.exists() else ""
    if existing and not existing.startswith(GENERATED):
        return "kept (`screenshots.nix` is not from this command)"
    for source, screenshots in candidates(name, app, store):
        locked = lock(screenshots, args.max)
        if not locked:
            continue
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


def check(name: str, app: dict) -> str:
    _current.app = name
    screenshots = app["lockedScreenshots"]
    broken = 0
    for screenshot in screenshots:
        url, expected = screenshot["url"], screenshot["hash"]
        # Some servers sometimes send other data. Thus, try a second time.
        for _ in range(2):
            actual = prefetch(url)
            if actual == expected:
                info(f"{url}: ok")
                break
        else:
            info(f"{url}: broken")
            if actual is not None:
                warn(f"hash mismatch: {url}: expected {expected}, got {actual}")
            broken += 1
    if broken:
        return f"broken ({broken} of {len(screenshots)} screenshots)"
    return f"ok ({len(screenshots)} screenshots)"


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
    parser.add_argument(
        "--check",
        action="store_true",
        help="check that the screenshot URLs can be fetched and have the same hash",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="print the steps for each application",
    )
    args = parser.parse_args()
    global VERBOSE
    VERBOSE = args.verbose

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
        if args.check:
            results = executor.map(lambda name: check(name, apps[name]), names)
        else:
            results = executor.map(
                lambda name: update(name, apps[name], store, root, args), names
            )
        broken = False
        for name, outcome in zip(names, results):
            print(f"{name}: {outcome}")
            broken = broken or outcome.startswith("broken")
    if broken:
        sys.exit(1)


if __name__ == "__main__":
    main()
