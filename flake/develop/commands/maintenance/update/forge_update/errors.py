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


def _format_build_stderr(stderr: str, max_lines: int = 20) -> str:
    lines = stderr.strip().splitlines()
    if not lines:
        return ""

    lines = lines[-max_lines:]
    body = "\n".join(f"    {line}" for line in lines)

    return body


class BuildError(ForgeUpdateError):
    exit_code: int
    stderr: str

    def __init__(self, pname: str, exit_code: int, stderr: str) -> None:
        self.exit_code = exit_code
        self.stderr = stderr

        msg = f"Build of '{pname}' failed (exit {exit_code})"
        extra = _format_build_stderr(stderr)

        if extra:
            msg += f"\n{extra}"

        super().__init__(msg)


class UnsupportedRecipeError(ForgeUpdateError):
    def __init__(self, pname: str, reason: str) -> None:
        super().__init__(f"'{pname}' cannot be auto-updated: {reason}")
