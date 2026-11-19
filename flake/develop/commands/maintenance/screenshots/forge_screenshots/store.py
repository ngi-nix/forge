import json
import os
from collections.abc import Iterator
from pathlib import Path, PurePosixPath

from .log import info, warn
from .nix import last_line, nix

SUBSTITUTERS = ["https://cache.nixos.org", "https://ngi-forge.cachix.org"]
# Directories in package sources that do not contain the metainfo file of the
# application.
SKIPPED_SOURCE_DIRS = {"node_modules", "test", "tests", "third_party", "vendor"}


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
            info(
                f"`{root}` is not in the local store or in a binary cache, fetching it"
            )
            result = nix("build", "--no-link", f"{drv}^out")
            if result.returncode != 0:
                warn(f"cannot fetch `{root}`: {last_line(result.stderr)}")
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
