"""forge-update: Update forge package recipes to latest upstream versions."""

import argparse
from pathlib import Path

from .forge_update.recipe import (
    RecipeParser,
    RecipeWriter,
)


class Args(argparse.Namespace):
    recipe: list[str] = []
    version: str | None = None
    dry_run: bool = False
    recipes_root: Path = Path("recipes/packages")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Update forge package recipes to latest upstream versions",
    )

    _ = parser.add_argument("recipe", nargs="+")
    _ = parser.add_argument("--version")
    _ = parser.add_argument("--dry-run", action="store_true")
    _ = parser.add_argument(
        "--recipes-root",
        type=Path,
        default=Path("recipes/packages"),
    )

    return parser


def parse_args(argv: list[str] | None = None) -> Args:
    return build_parser().parse_args(argv, namespace=Args())


def main() -> None:
    args = parse_args()
    parser = RecipeParser(args.recipes_root)
    writer = RecipeWriter(dry_run=args.dry_run)

    for name in args.recipe:
        path = parser.find(name)
        recipe = parser.parse(path)
        print(f"{name} ({path.parent.resolve()}/recipe.nix):")
        for pkg in recipe.packages:
            btype = pkg.builder_type.name
            print(f"  packages.{pkg.pname}")
            print(f"    version:     {pkg.version}")
            print(f"    builder:     {btype}")
            if pkg.source.type.name == "GIT":
                g = pkg.source.git
                if g:
                    print(f"    git:         {g.host.value}:{g.owner}/{g.repo}@{g.rev}")
            print(f"    source hash: {pkg.source.hash or '(none)'}")
            h = pkg.builder_hashes
            if h.cargo_hash:
                print(f"    cargoHash:   {h.cargo_hash}")
            if h.vendor_hash:
                print(f"    vendorHash:  {h.vendor_hash}")
            if h.npm_deps_hash:
                print(f"    npmDepsHash: {h.npm_deps_hash}")
            if h.pnpm_deps_hash:
                print(f"    pnpmDepsHash:{h.pnpm_deps_hash}")

        if args.version and recipe.packages:
            pkg = recipe.packages[0]
            writer.update_version(recipe, pkg.pname, args.version)
            writer.apply(recipe)


if __name__ == "__main__":
    main()
