"""forge-update: Update forge package recipes to latest upstream versions."""

import argparse
import sys
from pathlib import Path

# At build time default.nix replaces @forgeUpdateDir@ with the Nix-store
# path of this directory, making the sibling forge_update/ package
# importable when this script runs inside its Nix wrapper.
sys.path.insert(0, "@forgeUpdateDir@")
from forge_update.recipe import (  # pyright: ignore[reportImplicitRelativeImport]
    RecipeParser,
    RecipeWriter,
)
from forge_update.version import (  # pyright: ignore[reportImplicitRelativeImport]
    VersionDetector,
    VersionResult,
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
    detector = VersionDetector()

    for i, name in enumerate(args.recipe):
        if i > 0:
            print()

        path = parser.find(name)
        recipe = parser.parse(path)
        pkg = recipe.packages[0]
        writer = RecipeWriter(dry_run=args.dry_run)

        if args.version:
            result = VersionResult(version=args.version, rev="")
        else:
            result = detector.detect(recipe)

        g = pkg.source.git
        current_rev = g.rev if g else ""
        rev_changed = bool(result.rev) and result.rev != current_rev
        version_changed = pkg.version != result.version

        print(name)

        if not version_changed and not rev_changed:
            print(f"  already at {pkg.version}")
            continue

        writer.update_version(recipe, pkg.pname, result.version)
        if result.rev:
            writer.update_git_rev(recipe, pkg.pname, result.rev)

        for field, old, new in writer.pending_changes:
            print(f"  {field}")
            print(f"    {old}  ->")
            print(f"    {new}")

        writer.apply(recipe)


if __name__ == "__main__":
    main()
