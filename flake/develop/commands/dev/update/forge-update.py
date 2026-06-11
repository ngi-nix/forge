"""forge-update: Update forge package recipes to latest upstream versions."""

import argparse
from pathlib import Path


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

    print(f"Recipes to update: {args.recipe}")
    print(f"  recipes-root: {args.recipes_root}")
    if args.version:
        print(f"  explicit version: {args.version}")
    if args.dry_run:
        print("  dry-run: enabled")


if __name__ == "__main__":
    main()
