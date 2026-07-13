import re
from pathlib import Path

from . import regexes
from .errors import RecipeNotFoundError, RecipeParseError, UnsupportedRecipeError
from .types import (
    BuilderHashes,
    BuilderType,
    ForgeHost,
    GitSource,
    PackageEntry,
    PathSource,
    Recipe,
    Source,
    SourceType,
    UrlSource,
)


def _extract_braced_block(text: str, brace_start: int) -> tuple[int, str]:
    """Return (end_pos, block_text) for the balanced brace pair at brace_start."""
    depth = 1
    pos = brace_start + 1
    while pos < len(text) and depth > 0:
        if text[pos] == "{":
            depth += 1
        elif text[pos] == "}":
            depth -= 1
        pos += 1
    return pos, text[brace_start:pos]


class RecipeParser:
    recipes_root: Path

    def __init__(self, recipes_root: Path) -> None:
        self.recipes_root = recipes_root

    def find(self, name: str) -> Path:
        path = self.recipes_root / name / "recipe.nix"
        if not path.exists():
            raise RecipeNotFoundError(name, self.recipes_root)
        return path

    def parse(self, path: Path) -> Recipe:
        lines = path.read_text().splitlines(keepends=True)
        text = "".join(lines)

        blocks = self._extract_package_blocks(text)
        if not blocks:
            raise RecipeParseError(path, "no package declarations found")

        packages: list[PackageEntry] = []
        for pname, block_text in blocks:
            try:
                version = self._extract_version(block_text, path)
                source = self._parse_source(block_text, path)
            except RecipeParseError:
                if re.search(r"\binherit\b", block_text):
                    raise UnsupportedRecipeError(
                        pname, "package is inherited from another recipe"
                    ) from None
                raise
            builder_type, builder_hashes = self._parse_builder(block_text)
            packages.append(
                PackageEntry(
                    pname=pname,
                    version=version,
                    source=source,
                    builder_type=builder_type,
                    builder_hashes=builder_hashes,
                )
            )

        return Recipe(
            rel_path=path.parent,
            abs_path=path,
            raw_lines=lines,
            packages=packages,
        )

    def _extract_package_blocks(self, text: str) -> list[tuple[str, str]]:
        """Find each pkgs.<name> = { ... } block via brace-counting.

        Pure regex cannot match balanced braces, so we scan
        character-by-character counting depth instead.
        """
        blocks: list[tuple[str, str]] = []
        for match in re.finditer(regexes.PACKAGE_BLOCK, text):
            pname = match.group(1)
            start = match.start()
            end_pos, _ = _extract_braced_block(text, match.end() - 1)
            blocks.append((pname, text[start:end_pos]))
        return blocks

    def _extract_version(self, text: str, path: Path) -> str:
        match = re.search(regexes.FIELD_VERSION, text)
        if not match:
            raise RecipeParseError(path, "version field not found")
        return match.group(1)

    def _parse_source(self, text: str, path: Path) -> Source:
        """Parse source fields from a scoped package block.

        Within a `pkgs.<name> = { ... }` block each source field
        (git/url/path) appears at most once, so plain word-boundary
        matching is sufficient.
        """
        source_hash = self._extract_source_hash(text)

        git_match = re.search(regexes.FIELD_GIT, text)
        if git_match:
            return Source(
                type=SourceType.GIT,
                git=self._parse_git(git_match.group(1), text, path),
                hash=source_hash,
            )

        url_match = re.search(regexes.FIELD_URL, text)
        if url_match:
            return Source(
                type=SourceType.URL,
                url=UrlSource(url=url_match.group(1)),
                hash=source_hash,
            )

        path_match = re.search(regexes.FIELD_PATH, text)
        if path_match:
            return Source(
                type=SourceType.PATH,
                path=PathSource(path=Path(path_match.group(1))),
            )

        raise RecipeParseError(path, "no source (git/url/path) found")

    def _extract_source_hash(self, text: str) -> str:
        match = re.search(regexes.FIELD_HASH, text)
        return match.group(1) if match else ""

    def _parse_git(self, spec: str, text: str, path: Path) -> GitSource:
        parts = spec.split(":")
        forge_str = parts[0]
        rest = ":".join(parts[1:])

        try:
            host = ForgeHost(forge_str)
        except ValueError:
            raise RecipeParseError(path, f"unknown forge host in git spec: {forge_str}")

        if host == ForgeHost.GENERIC_GIT:
            return self._parse_generic_git(rest, text)

        path_parts = rest.split("/")
        path_len = len(path_parts)

        if path_len == 3:
            owner, repo, rev = path_parts
        elif path_len == 4:
            _, owner, repo, rev = path_parts
        else:
            raise RecipeParseError(path, f"cannot parse git spec: {spec}")

        submodules = bool(re.search(regexes.SUBMODULES, text))

        remote_url = self._forge_remote_url(host, owner, repo)

        return GitSource(
            host=host,
            owner=owner,
            repo=repo,
            rev=rev,
            remote_url=remote_url,
            submodules=submodules,
        )

    @staticmethod
    def _forge_remote_url(host: ForgeHost, owner: str, repo: str) -> str:
        match host:
            case ForgeHost.CODEBERG | ForgeHost.FORGEJO:
                return f"https://{host.value}.org/{owner}/{repo}"
            case _:
                return f"https://{host.value}.com/{owner}/{repo}"

    def _parse_generic_git(self, rest: str, text: str) -> GitSource:
        rev_match = re.search(regexes.GIT_REV, rest)
        rev = rev_match.group(1) if rev_match else "HEAD"

        remote_url = rest.split("?")[0] if "?" in rest else rest

        submodules = bool(re.search(regexes.SUBMODULES, text))

        return GitSource(
            host=ForgeHost.GENERIC_GIT,
            owner="",
            repo="",
            rev=rev,
            remote_url=remote_url,
            submodules=submodules,
        )

    def _parse_builder(self, text: str) -> tuple[BuilderType, BuilderHashes]:
        builder_map: dict[str, BuilderType] = {
            "standard": BuilderType.STANDARD,
            "rustPackage": BuilderType.RUST,
            "goPackage": BuilderType.GO,
            "npm": BuilderType.NPM,
            "pnpm": BuilderType.PNPM,
            "pythonApp": BuilderType.PYTHON_APP,
            "pythonPackage": BuilderType.PYTHON_PACKAGE,
        }

        for match in re.finditer(regexes.BUILDER_DECL, text):
            _, block_text = _extract_braced_block(text, match.end() - 1)
            if re.search(r"\benable\b\s*=\s*true", block_text):
                builder_key = match.group(1)
                builder_type = builder_map.get(builder_key, BuilderType.STANDARD)

                hashes = BuilderHashes()
                cargo = re.search(regexes.FIELD_CARGO_HASH, text)
                if cargo:
                    hashes.cargo_hash = cargo.group(1)
                vendor = re.search(regexes.FIELD_VENDOR_HASH, text)
                if vendor:
                    hashes.vendor_hash = vendor.group(1)
                npm = re.search(regexes.FIELD_NPM_DEPS_HASH, text)
                if npm:
                    hashes.npm_deps_hash = npm.group(1)
                pnpm = re.search(regexes.FIELD_PNPM_DEPS_HASH, text)
                if pnpm:
                    hashes.pnpm_deps_hash = pnpm.group(1)

                return builder_type, hashes

        return BuilderType.STANDARD, BuilderHashes()


class RecipeWriter:
    dry_run: bool
    pending_changes: list[tuple[str, str, str]]

    def __init__(self, dry_run: bool = False) -> None:
        self.dry_run = dry_run
        self.pending_changes = []

    def update_version(self, recipe: Recipe, pname: str, new_version: str) -> None:
        self._replace(
            recipe,
            pname,
            regexes.FIELD_VERSION,
            f'version = "{new_version}"',
            "version",
        )

    def update_source_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        self._replace(
            recipe,
            pname,
            regexes.FIELD_HASH,
            f'hash = "{new_hash}"',
            "source.hash",
        )

    def update_cargo_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        self._replace(
            recipe,
            pname,
            regexes.FIELD_CARGO_HASH,
            f'cargoHash = "{new_hash}"',
            "cargoHash",
        )

    def update_vendor_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        self._replace(
            recipe,
            pname,
            regexes.FIELD_VENDOR_HASH,
            f'vendorHash = "{new_hash}"',
            "vendorHash",
        )

    def update_npm_deps_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        self._replace(
            recipe,
            pname,
            regexes.FIELD_NPM_DEPS_HASH,
            f'npmDepsHash = "{new_hash}"',
            "npmDepsHash",
        )

    def update_pnpm_deps_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        self._replace(
            recipe,
            pname,
            regexes.FIELD_PNPM_DEPS_HASH,
            f'pnpmDepsHash = "{new_hash}"',
            "pnpmDepsHash",
        )

    def update_git_rev(self, recipe: Recipe, pname: str, new_rev: str) -> None:
        text = "".join(recipe.raw_lines)
        _, _, block_text = self._find_package_block(text, pname, recipe.abs_path)

        match = re.search(regexes.FIELD_GIT, block_text)
        if not match:
            raise RecipeParseError(recipe.abs_path, f"cannot find git spec for {pname}")
        old_git = match.group(1)

        if old_git.startswith("git:"):
            # Generic git: replace tag= or rev= query-param value
            # e.g. git:https://example.com/repo?tag=0.3.0 → ?tag=<new>
            new_git = re.sub(r"(tag|rev)=([^&\"]*)", rf"\1={new_rev}", old_git, count=1)
        else:
            # Forge-host: replace last /-separated component
            new_git = old_git.rsplit("/", 1)[0] + "/" + new_rev

        self._replace(recipe, pname, regexes.FIELD_GIT, f'git = "{new_git}"', "git")

    def _find_package_block(
        self, text: str, pname: str, abs_path: Path
    ) -> tuple[int, int, str]:
        """Return (start, end, block-text) for a `packages.<pname>` block.

        Uses the same brace-counting approach as `_extract_package_blocks`
        so that nested { } inside builder configs don't confuse the scan.
        """
        for match in re.finditer(rf"pkgs\.{re.escape(pname)}\s*=\s*\{{", text):
            start = match.start()
            end_pos, block_text = _extract_braced_block(text, match.end() - 1)
            return start, end_pos, text[start:end_pos]
        raise RecipeParseError(abs_path, f"package '{pname}' not found for replacement")

    def _replace(
        self, recipe: Recipe, pname: str, pattern: str, replacement: str, field: str
    ) -> None:
        text = "".join(recipe.raw_lines)

        block_start, block_end, block_text = self._find_package_block(
            text, pname, recipe.abs_path
        )

        new_block, count = re.subn(pattern, replacement, block_text, count=1)
        if count == 0:
            raise RecipeParseError(recipe.abs_path, f"cannot find {field} for {pname}")

        new_text = text[:block_start] + new_block + text[block_end:]
        recipe.raw_lines = new_text.splitlines(keepends=True)

        old_match = re.search(pattern, block_text)
        old_value = old_match.group(1) if old_match else "?"
        self.pending_changes.append(
            (
                field,
                old_value,
                replacement.split('"')[1] if '"' in replacement else replacement,
            )
        )

    def apply(self, recipe: Recipe) -> None:
        if not self.dry_run:
            _ = recipe.abs_path.write_text("".join(recipe.raw_lines))
