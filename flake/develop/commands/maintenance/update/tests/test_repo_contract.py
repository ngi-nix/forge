"""Contract: every recipe in the repository is either parseable or excluded.

These tests read the checkout's real ``recipes/pkgs`` tree, so they are marked
``contract`` and deselected by default. Run them from a full checkout with::

    pytest -m contract

The exclusions below are deliberate: each recipe references a value from
another package and cannot be updated by this tool. A new recipe that fails to
parse is therefore a test failure, not a silent omission.

The allowlist is exhaustive by construction: the tests below parametrize over
every ``recipe.nix`` found in the tree, so a new recipe is always covered. If
it parses, nothing needs to change; if it does not, the parse test fails until
the recipe is added to ``KNOWN_UNSUPPORTED`` with the exception it raises (or
the parser learns to handle it). An allowlist entry whose recipe has been
removed also fails, so the list cannot drift away from the tree.
"""

from pathlib import Path

import pytest

from forge_update.errors import RecipeParseError, UnsupportedRecipeError
from forge_update.recipe import RecipeParser
from forge_update.types import SourceType


def _find_recipes_root() -> Path | None:
    """Nearest ancestor that has ``recipes/pkgs``, if the checkout has one."""
    for parent in Path(__file__).resolve().parents:
        candidate = parent / "recipes" / "pkgs"
        if candidate.is_dir():
            return candidate
    return None


RECIPES_ROOT = _find_recipes_root()

# Recipes expected to be rejected, with the error the parser raises today.
# Keep this exhaustive: any recipe not listed here is parsed by
# ``test_every_supported_recipe_parses`` and must therefore be supported.
KNOWN_UNSUPPORTED: dict[str, type[Exception]] = {
    # Packages that inherit from a sibling declared earlier in the same file.
    "kazarma": UnsupportedRecipeError,
    "ocaml-quic": UnsupportedRecipeError,
    "offen-auditorium": UnsupportedRecipeError,
    "offen-script": UnsupportedRecipeError,
    "offen-vault": UnsupportedRecipeError,
    "qlever-ui-frontend": UnsupportedRecipeError,
    # ``version = pkgs.repath-studio.version`` is an expression rather than a
    # string literal, so parsing stops before the version is known.
    "repath-studio-web": RecipeParseError,
}

pytestmark = [
    pytest.mark.contract,
    pytest.mark.skipif(
        RECIPES_ROOT is None,
        reason="recipes/pkgs is not available (Nix sandbox)",
    ),
]


def _recipe_paths() -> list[Path]:
    """Every ``recipe.nix`` below ``recipes/pkgs``, relative to its root."""
    recipes_root = RECIPES_ROOT
    if recipes_root is None:
        return []
    return sorted(
        path.relative_to(recipes_root) for path in recipes_root.glob("**/recipe.nix")
    )


def _case_id(recipe_path: Path) -> str:
    return str(recipe_path.parent)


@pytest.mark.parametrize(
    "recipe_path",
    [path for path in _recipe_paths() if path.parent.name not in KNOWN_UNSUPPORTED],
    ids=_case_id,
)
def test_every_supported_recipe_parses(recipe_path: Path) -> None:
    recipes_root = RECIPES_ROOT
    assert recipes_root is not None  # narrowing; pytestmark skips if missing

    recipe = RecipeParser(recipes_root).parse_recipe_file(recipes_root / recipe_path)

    assert recipe.packages
    package = recipe.packages[0]
    assert package.pname
    assert package.version

    source = package.source
    match source.type:
        case SourceType.GIT:
            assert source.git is not None
        case SourceType.URL:
            assert source.url is not None
        case SourceType.PATH:
            assert source.path is not None


@pytest.mark.parametrize(("name", "error"), sorted(KNOWN_UNSUPPORTED.items()))
def test_known_unsupported_recipes_are_rejected(
    name: str, error: type[Exception]
) -> None:
    recipes_root = RECIPES_ROOT
    assert recipes_root is not None  # narrowing; pytestmark skips if missing

    with pytest.raises(error):
        _ = RecipeParser(recipes_root).parse_recipe_file(
            recipes_root / name / "recipe.nix"
        )


def test_known_unsupported_recipes_exist() -> None:
    """An allowlist entry whose recipe is gone is stale, not harmless."""
    recipe_paths = _recipe_paths()
    names = {str(path.parent) for path in recipe_paths}
    stale = sorted(set(KNOWN_UNSUPPORTED) - names)

    assert not stale, (
        "KNOWN_UNSUPPORTED lists recipes that no longer exist; remove them: "
        + ", ".join(stale)
    )
