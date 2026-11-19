import re
from pathlib import Path

from nix_manipulator import parse
from nix_manipulator.exceptions import ResolutionError
from nix_manipulator.expressions import (
    AttributeSet,
    Identifier,
    Inherit,
    NixSourceCode,
    Primitive,
)

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


class RecipeParser:
    recipes_root: Path

    def __init__(self, recipes_root: Path) -> None:
        self.recipes_root = recipes_root

    def get_recipe_file(self, name: str) -> Path:
        path = self.recipes_root / name / "recipe.nix"
        if not path.exists():
            raise RecipeNotFoundError(name, self.recipes_root)
        return path

    def parse_recipe_file(self, path: Path) -> Recipe:
        lines = path.read_text().splitlines(keepends=True)
        text = "".join(lines)
        try:
            source_ast = parse(text)
        except Exception as e:
            raise RecipeParseError(path, f"failed to parse recipe: {e}") from e

        try:
            pkgs_set = source_ast["pkgs"]
        except (KeyError, ValueError):
            raise RecipeParseError(path, "no package declarations found")

        packages: list[PackageEntry] = []
        for item in pkgs_set.values:
            if not hasattr(item, "name"):
                continue
            pname = item.name.strip('"')
            block = item.value
            if not isinstance(block, AttributeSet):
                continue

            has_version_inherit = False
            for val in block.values:
                if isinstance(val, Inherit):
                    for name_expr in val.names:
                        name_str = (
                            name_expr.name
                            if isinstance(name_expr, Identifier)
                            else getattr(name_expr, "value", "")
                        )
                        if name_str in ("version", "source"):
                            has_version_inherit = True
                            break

            try:
                ver_node = block["version"]
                if isinstance(ver_node, Primitive):
                    version = str(ver_node.value)
                else:
                    try:
                        val = ver_node.value
                        version = (
                            str(val)
                            if not isinstance(val, (AttributeSet, Inherit))
                            else ver_node.rebuild().strip()
                        )
                    except ResolutionError:
                        if has_version_inherit:
                            raise UnsupportedRecipeError(
                                pname, "package is inherited from another recipe"
                            )
                        version = ver_node.rebuild().strip()
            except KeyError:
                if has_version_inherit:
                    raise UnsupportedRecipeError(
                        pname, "package is inherited from another recipe"
                    )
                raise RecipeParseError(path, "version field not found")

            try:
                source_entry = self._parse_source(block, path)
            except RecipeParseError:
                if has_version_inherit:
                    raise UnsupportedRecipeError(
                        pname, "package is inherited from another recipe"
                    )
                raise

            builder_type, builder_hashes = self._parse_builder(block)
            packages.append(
                PackageEntry(
                    pname=pname,
                    version=version,
                    source=source_entry,
                    builder_type=builder_type,
                    builder_hashes=builder_hashes,
                )
            )

        if not packages:
            raise RecipeParseError(path, "no package declarations found")

        return Recipe(
            rel_path=path.parent,
            abs_path=path,
            raw_lines=lines,
            packages=packages,
        )

    def _parse_source(self, block: AttributeSet, path: Path) -> Source:
        try:
            src_node = block["source"]
        except KeyError:
            raise RecipeParseError(path, "no source (git/url/path) found")

        source_hash = ""
        try:
            source_hash = str(src_node["hash"].value)
        except (KeyError, AttributeError):
            pass

        try:
            git_spec = str(src_node["git"].value)
            submodules = False
            try:
                submodules = bool(src_node["submodules"].value)
            except (KeyError, AttributeError):
                pass
            git_source = self._parse_git(git_spec, submodules, path)
            return Source(type=SourceType.GIT, git=git_source, hash=source_hash)
        except KeyError:
            pass

        try:
            url_val = str(src_node["url"].value)
            return Source(
                type=SourceType.URL,
                url=UrlSource(url=url_val),
                hash=source_hash,
            )
        except KeyError:
            pass

        try:
            path_val = str(src_node["path"].value)
            return Source(
                type=SourceType.PATH,
                path=PathSource(path=Path(path_val)),
            )
        except KeyError:
            pass

        raise RecipeParseError(path, "no source (git/url/path) found")

    def _parse_git(self, spec: str, submodules: bool, path: Path) -> GitSource:
        parts = spec.split(":")
        forge_str = parts[0]
        rest = ":".join(parts[1:])

        try:
            host = ForgeHost(forge_str)
        except ValueError:
            raise RecipeParseError(path, f"unknown forge host in git spec: {forge_str}")

        if host == ForgeHost.GENERIC_GIT:
            return self._parse_generic_git(rest, submodules)

        path_parts = rest.split("/")
        path_len = len(path_parts)

        if path_len == 3:
            owner, repo, rev = path_parts
        elif path_len == 4:
            _, owner, repo, rev = path_parts
        else:
            raise RecipeParseError(path, f"cannot parse git spec: {spec}")

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

    def _parse_generic_git(self, rest: str, submodules: bool) -> GitSource:
        rev_match = re.search(regexes.GIT_REV, rest)
        rev = rev_match.group(1) if rev_match else "HEAD"

        remote_url = rest.split("?")[0] if "?" in rest else rest

        return GitSource(
            host=ForgeHost.GENERIC_GIT,
            owner="",
            repo="",
            rev=rev,
            remote_url=remote_url,
            submodules=submodules,
        )

    def _parse_builder(self, block: AttributeSet) -> tuple[BuilderType, BuilderHashes]:
        builder_map: dict[str, BuilderType] = {
            "go": BuilderType.GO,
            "npm": BuilderType.NPM,
            "ocaml": BuilderType.OCAML,
            "pnpm": BuilderType.PNPM,
            "python": BuilderType.PYTHON,
            "pythonModule": BuilderType.PYTHON_MODULE,
            "rust": BuilderType.RUST,
            "standard": BuilderType.STANDARD,
        }

        try:
            builders = block["build"]["builders"]
            for b in builders.values:
                if isinstance(b.value, AttributeSet):
                    try:
                        if b.value["enable"].value is True:
                            builder_type = builder_map.get(b.name, BuilderType.STANDARD)
                            hashes = BuilderHashes()
                            for h_field, h_attr in [
                                ("cargoHash", "cargo_hash"),
                                ("vendorHash", "vendor_hash"),
                                ("npmDepsHash", "npm_deps_hash"),
                                ("pnpmDepsHash", "pnpm_deps_hash"),
                            ]:
                                try:
                                    setattr(hashes, h_attr, str(b.value[h_field].value))
                                except KeyError:
                                    pass
                            return builder_type, hashes
                    except KeyError:
                        pass
        except (KeyError, TypeError):
            pass

        return BuilderType.STANDARD, BuilderHashes()


class RecipeWriter:
    dry_run: bool
    pending_changes: list[tuple[str, str, str]]

    def __init__(self, dry_run: bool = False) -> None:
        self.dry_run = dry_run
        self.pending_changes = []

    def _get_ast(self, recipe: Recipe) -> NixSourceCode:
        text = "".join(recipe.raw_lines)
        try:
            return parse(text)
        except Exception as e:
            raise RecipeParseError(
                recipe.abs_path, f"failed to parse recipe: {e}"
            ) from e

    def _get_pkg(
        self, source: NixSourceCode, pname: str, abs_path: Path
    ) -> AttributeSet:
        try:
            pkgs = source["pkgs"]
        except (KeyError, ValueError) as e:
            raise RecipeParseError(
                abs_path, f"no 'pkgs' attribute set found: {e}"
            ) from e
        try:
            return pkgs[pname]
        except KeyError:
            try:
                return pkgs[f'"{pname}"']
            except KeyError:
                raise RecipeParseError(
                    abs_path, f"package '{pname}' not found for replacement"
                ) from None

    def _save_ast(self, recipe: Recipe, source: NixSourceCode) -> None:
        new_text = source.rebuild()
        recipe.raw_lines = new_text.splitlines(keepends=True)

    def update_version(self, recipe: Recipe, pname: str, new_version: str) -> None:
        source = self._get_ast(recipe)
        pkg = self._get_pkg(source, pname, recipe.abs_path)
        try:
            old_val = str(pkg["version"].value)
        except KeyError:
            raise RecipeParseError(
                recipe.abs_path, f"cannot find version for {pname}"
            ) from None
        pkg["version"] = new_version
        self._save_ast(recipe, source)
        self.pending_changes.append(("version", old_val, new_version))

    def update_source_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        source = self._get_ast(recipe)
        pkg = self._get_pkg(source, pname, recipe.abs_path)
        try:
            old_val = str(pkg["source"]["hash"].value)
        except KeyError:
            raise RecipeParseError(
                recipe.abs_path, f"cannot find source.hash for {pname}"
            ) from None
        pkg["source"]["hash"] = new_hash
        self._save_ast(recipe, source)
        self.pending_changes.append(("source.hash", old_val, new_hash))

    def _update_builder_hash(
        self, recipe: Recipe, pname: str, hash_attr: str, new_hash: str
    ) -> None:
        source = self._get_ast(recipe)
        pkg = self._get_pkg(source, pname, recipe.abs_path)
        try:
            builders = pkg["build"]["builders"]
            for b in builders.values:
                if isinstance(b.value, AttributeSet):
                    try:
                        old_val = str(b.value[hash_attr].value)
                        b.value[hash_attr] = new_hash
                        self._save_ast(recipe, source)
                        self.pending_changes.append((hash_attr, old_val, new_hash))
                        return
                    except KeyError:
                        continue
        except (KeyError, TypeError):
            pass

        try:
            old_val = str(pkg[hash_attr].value)
            pkg[hash_attr] = new_hash
            self._save_ast(recipe, source)
            self.pending_changes.append((hash_attr, old_val, new_hash))
            return
        except KeyError:
            pass

        raise RecipeParseError(recipe.abs_path, f"cannot find {hash_attr} for {pname}")

    def update_cargo_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        self._update_builder_hash(recipe, pname, "cargoHash", new_hash)

    def update_vendor_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        self._update_builder_hash(recipe, pname, "vendorHash", new_hash)

    def update_npm_deps_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        self._update_builder_hash(recipe, pname, "npmDepsHash", new_hash)

    def update_pnpm_deps_hash(self, recipe: Recipe, pname: str, new_hash: str) -> None:
        self._update_builder_hash(recipe, pname, "pnpmDepsHash", new_hash)

    def update_git_rev(self, recipe: Recipe, pname: str, new_rev: str) -> None:
        source = self._get_ast(recipe)
        pkg = self._get_pkg(source, pname, recipe.abs_path)
        try:
            old_git = str(pkg["source"]["git"].value)
        except KeyError:
            raise RecipeParseError(
                recipe.abs_path, f"cannot find git spec for {pname}"
            ) from None

        if old_git.startswith("git:"):
            # Generic git: replace tag= or rev= query-param value
            # e.g. git:https://example.com/repo?tag=0.3.0 → ?tag=<new>
            new_git = re.sub(r"(tag|rev)=([^&\"]*)", rf"\1={new_rev}", old_git, count=1)
        else:
            # Forge-host: replace last /-separated component
            new_git = old_git.rsplit("/", 1)[0] + "/" + new_rev

        pkg["source"]["git"] = new_git
        self._save_ast(recipe, source)
        self.pending_changes.append(("git", old_git, new_git))

    def apply_text(self, recipe: Recipe, text: str | None = None) -> None:
        """
        Open the recipe file, write to it, and close the file.

        If no `text` argument is supplied, the in-memory recipe text will be written.
        """
        if not self.dry_run:
            in_memory_text = "".join(recipe.raw_lines)
            _ = recipe.abs_path.write_text(text if text is not None else in_memory_text)
