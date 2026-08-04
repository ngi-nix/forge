from pathlib import Path

from .types import Source


class ForgeUpdateError(Exception):
    """Base for all forge-update errors."""


class RecipeNotFoundError(ForgeUpdateError):
    def __init__(self, name: str, search_dir: Path) -> None:
        super().__init__(f"Recipe '{name}' not found in {search_dir}")


class RecipeParseError(ForgeUpdateError):
    def __init__(self, path: Path, detail: str) -> None:
        super().__init__(f"Failed to parse {path}: {detail}")


class VersionDetectionError(ForgeUpdateError):
    def __init__(self, source: Source, detail: str) -> None:
        super().__init__(f"Cannot detect version from {source.type.name}: {detail}")


class PrefetchError(ForgeUpdateError):
    def __init__(self, detail: str) -> None:
        super().__init__(f"Prefetch failed: {detail}")


class BuildError(ForgeUpdateError):
    exit_code: int
    stderr: str

    def __init__(self, pname: str, exit_code: int, stderr: str) -> None:
        super().__init__(f"Build of '{pname}' failed (exit {exit_code})")
        self.exit_code = exit_code
        self.stderr = stderr


class UnsupportedRecipeError(ForgeUpdateError):
    def __init__(self, pname: str, reason: str) -> None:
        super().__init__(f"'{pname}' cannot be auto-updated: {reason}")
