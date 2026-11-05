import re
import subprocess

from typing import Callable

from . import regexes
from .errors import BuildError
from .recipe import Recipe, RecipeWriter
from .types import BuilderType, PackageEntry

HASH_MISMATCH_RE = re.compile(regexes.NIX_BUILD_GOT_HASH)


class BuilderHashUpdater:
    build_timeout: int = 300

    def __init__(self, dry_run: bool = False) -> None:
        self.dry_run = dry_run

    def field_name(self, pkg: PackageEntry) -> str | None:
        match pkg.builder_type:
            case BuilderType.GO:
                bh = pkg.builder_hashes
                if bh is not None and bh.vendor_hash is not None:
                    return "vendorHash"
                return None
            case BuilderType.RUST:
                return "cargoHash"
            case BuilderType.NPM:
                return "npmDepsHash"
            case BuilderType.PNPM:
                return "pnpmDepsHash"
            case _:
                return None

    def update(self, recipe: Recipe, writer: RecipeWriter, pkg: PackageEntry) -> None:
        match pkg.builder_type:
            case BuilderType.RUST:
                self._update_single(
                    recipe, pkg.pname, writer, "cargoHash", writer.update_cargo_hash
                )
            case BuilderType.GO:
                bh = pkg.builder_hashes
                if bh is not None and bh.vendor_hash is not None:
                    self._update_single(
                        recipe,
                        pkg.pname,
                        writer,
                        "vendorHash",
                        writer.update_vendor_hash,
                    )
            case BuilderType.NPM:
                self._update_single(
                    recipe,
                    pkg.pname,
                    writer,
                    "npmDepsHash",
                    writer.update_npm_deps_hash,
                )
            case BuilderType.PNPM:
                self._update_single(
                    recipe,
                    pkg.pname,
                    writer,
                    "pnpmDepsHash",
                    writer.update_pnpm_deps_hash,
                )
            case _:
                return

    def _update_single(
        self,
        recipe: Recipe,
        pname: str,
        writer: RecipeWriter,
        field_name: str,
        updater: Callable[..., None],
    ) -> None:
        if self.dry_run:
            return

        before = len(writer.pending_changes)

        recipe.abs_path.write_text("".join(recipe.raw_lines))

        updater(recipe, pname, "")
        recipe.abs_path.write_text("".join(recipe.raw_lines))

        try:
            result = subprocess.run(
                ["nix", "build", f".#{pname}"],
                capture_output=True,
                text=True,
                timeout=self.build_timeout,
            )
        except subprocess.TimeoutExpired:
            raise BuildError(pname, -1, f"nix build timed out ({self.build_timeout}s)")

        stderr = result.stderr or ""
        match = HASH_MISMATCH_RE.search(stderr)
        if not match:
            raise BuildError(pname, result.returncode, stderr)

        new_hash = match.group(1)
        updater(recipe, pname, new_hash)

        if len(writer.pending_changes) >= before + 2:
            old_val = writer.pending_changes[before][1]
            writer.pending_changes[before] = (
                field_name,
                old_val,
                new_hash,
            )
            del writer.pending_changes[before + 1]
