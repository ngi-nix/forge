import xml.etree.ElementTree as ET
from collections.abc import Iterator
from pathlib import PurePosixPath

from .log import count, info, warn
from .store import Store
from .types import Screenshot

METAINFO_DIRS = ["share/metainfo", "share/appdata"]
# Wrappers often link these directories, or the files in them, from the
# wrapped package.
LINKED_DIRS = ["share/applications", "share/icons"]
METAINFO_SUFFIXES = (".metainfo.xml", ".appdata.xml")
XML_LANG = "{http://www.w3.org/XML/1998/namespace}lang"


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
    info(f"looking for metainfo files in the package source `{source['path']}`")
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
        where = "the local store" if location == "local" else f"binary cache {location}"
        info(f"reading package `{package}` from {where}")
        for root in linked_roots(store, package):
            if root not in roots:
                if root != package:
                    info(
                        f"package `{package}` links desktop files or icons from"
                        f" `{root}`, looking for metainfo files there too"
                    )
                roots.append(root)
    files = [
        (f"AppStream metainfo `{name}`", root, data)
        for root in roots
        for name, data in metainfo_files(store, root)
    ]
    found = False
    for source, root, data in files:
        screenshots = parse(data, source, root)
        info(f"found {count(len(screenshots), 'screenshot')} in {source} in `{root}`")
        if screenshots:
            found = True
            yield source, screenshots
    # Use the sources only if the packages do not install metainfo with screenshots.
    if not found:
        info(
            "the packages have no metainfo files with screenshots,"
            " looking in the package sources"
        )
        for package_source in app["sources"]:
            for name, data in source_metainfo_files(store, package_source):
                screenshots = parse(data, f"`{name}`", package_source["path"])
                info(
                    f"found {count(len(screenshots), 'screenshot')} in `{name}`"
                    " in the package source"
                )
                if screenshots:
                    yield f"AppStream metainfo `{name}` in the package source", screenshots
