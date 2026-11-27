"""Parser and writer regressions in ``recipe.py``.

Everything runs against real files in ``tmp_path``; no git, Nix, or network
involved. The recipes are small strings tailored to one behavior each.
"""

from pathlib import Path
from typing import NamedTuple

import pytest
from conftest import HASH, INHERITED_RECIPE, git_recipe, path_recipe, url_recipe

from forge_update.errors import (
    RecipeNotFoundError,
    RecipeParseError,
    UnsupportedRecipeError,
)
from forge_update.recipe import RecipeParser, RecipeWriter
from forge_update.types import BuilderType, ForgeHost, Recipe, SourceType

UNKNOWN_HOST_RECIPE = git_recipe("bogus:owner/repo/v1.2.3")

GENERIC_BARE_RECIPE = git_recipe("git:https://example.com/repo.git")

THREE_SEGMENT_RECIPE = git_recipe()

FOUR_SEGMENT_RECIPE = git_recipe("gitlab:group/sub/repo/v1.2.3")

SUBMODULES_RECIPE = git_recipe(submodules=True)

NESTED_BRACES_RECIPE = f"""\
{{
  pkgs.demo = {{
    build.builders.standard = {{
      enable = true;
      hooks = {{
        preBuild = {{
          text = "nested";
        }};
      }};
    }};

    version = "1.2.3";

    source = {{
      git = "github:owner/repo/v1.2.3";
      hash = "{HASH}";
    }};
  }};
}}
"""

ENABLED_BUILDER_RECIPE = f"""\
{{
  pkgs.demo = {{
    version = "1.2.3";
    source = {{
      git = "github:owner/repo/v1.2.3";
      hash = "{HASH}";
    }};

    build.builders.rust = {{
      enable = true;
      cargoHash = "sha256-CARGO";
    }};

    build.builders.go = {{
      enable = false;
    }};
  }};
}}
"""

UNKNOWN_BUILDER_RECIPE = f"""\
{{
  pkgs.demo = {{
    version = "1.2.3";
    source = {{
      git = "github:owner/repo/v1.2.3";
      hash = "{HASH}";
    }};

    build.builders.weird = {{
      enable = true;
    }};
  }};
}}
"""

URL_RECIPE = url_recipe()

PATH_RECIPE = path_recipe()

MISSING_VERSION_RECIPE = """\
{
  pkgs.demo = {
    source = {
      url = "https://example.com/demo.tar.gz";
    };
  };
}
"""

MISSING_SOURCE_RECIPE = """\
{
  pkgs.demo = {
    version = "1.2.3";
    description = "no source here";
  };
}
"""


@pytest.fixture
def parser(recipes_root):
    return RecipeParser(recipes_root)


@pytest.fixture
def parse_recipe(parser, make_recipe):
    """Write ``text`` as a recipe and return the parsed result."""

    def _parse(text: str, name: str = "demo"):
        return parser.parse_recipe_file(make_recipe(name, text))

    return _parse


@pytest.fixture
def parse_error(parser, make_recipe):
    """Write ``text``, expect ``error`` while parsing, return the message."""

    def _error(
        text: str,
        error: type[Exception] = RecipeParseError,
        name: str = "demo",
    ) -> str:
        with pytest.raises(error) as err:
            _ = parser.parse_recipe_file(make_recipe(name, text))
        return str(err.value)

    return _error


class ParsedRecipe(NamedTuple):
    """A written recipe file and its parsed form."""

    path: Path
    recipe: Recipe


@pytest.fixture
def parsed_basic(parser, make_recipe, basic_recipe_text) -> ParsedRecipe:
    """The basic recipe written to disk, together with its parsed form."""
    path = make_recipe("demo", basic_recipe_text)
    return ParsedRecipe(path, parser.parse_recipe_file(path))


def test_get_recipe_file_returns_path(parser, make_recipe, basic_recipe_text) -> None:
    path = make_recipe("demo", basic_recipe_text)

    assert parser.get_recipe_file("demo") == path


def test_get_recipe_file_missing(parser, recipes_root) -> None:
    with pytest.raises(RecipeNotFoundError) as err:
        _ = parser.get_recipe_file("missing")

    assert f"Recipe 'missing' not found in {recipes_root}" in str(err.value)


def test_parse_requires_a_package_block(parse_error) -> None:
    message = parse_error("this is not a recipe\n")

    assert "no package declarations found" in message


def test_inherited_package_is_unsupported(parse_error) -> None:
    message = parse_error(INHERITED_RECIPE, UnsupportedRecipeError)

    assert "package is inherited from another recipe" in message


def test_unknown_forge_host_is_a_parse_error(parse_error) -> None:
    message = parse_error(UNKNOWN_HOST_RECIPE)

    assert "unknown forge host in git spec: bogus" in message


def test_generic_git_without_rev_defaults_to_head(parse_recipe) -> None:
    recipe = parse_recipe(GENERIC_BARE_RECIPE)

    git = recipe.packages[0].source.git
    assert git is not None
    assert git.host == ForgeHost.GENERIC_GIT
    assert git.rev == "HEAD"
    assert git.remote_url == "https://example.com/repo.git"


@pytest.mark.parametrize(
    ("text", "host", "owner", "repo", "remote"),
    [
        (
            THREE_SEGMENT_RECIPE,
            ForgeHost.GITHUB,
            "owner",
            "repo",
            "https://github.com/owner/repo",
        ),
        (
            FOUR_SEGMENT_RECIPE,
            ForgeHost.GITLAB,
            "sub",
            "repo",
            "https://gitlab.com/sub/repo",
        ),
    ],
    ids=["three-segments", "four-segments"],
)
def test_forge_git_paths(
    parse_recipe,
    text: str,
    host: ForgeHost,
    owner: str,
    repo: str,
    remote: str,
) -> None:
    recipe = parse_recipe(text)

    git = recipe.packages[0].source.git
    assert git is not None
    assert git.host == host
    assert git.owner == owner
    assert git.repo == repo
    assert git.rev == "v1.2.3"
    assert git.remote_url == remote


@pytest.mark.parametrize(
    ("text", "expected"),
    [
        (THREE_SEGMENT_RECIPE, False),
        (SUBMODULES_RECIPE, True),
    ],
    ids=["without-submodules", "with-submodules"],
)
def test_submodules_flag(parse_recipe, text: str, expected: bool) -> None:
    recipe = parse_recipe(text)

    git = recipe.packages[0].source.git
    assert git is not None
    assert git.submodules is expected


def test_nested_braces_do_not_truncate_the_block(parse_recipe) -> None:
    recipe = parse_recipe(NESTED_BRACES_RECIPE)

    package = recipe.packages[0]
    assert package.version == "1.2.3"
    assert package.source.git is not None
    assert package.source.git.rev == "v1.2.3"


def test_enabled_builder_wins(parse_recipe) -> None:
    recipe = parse_recipe(ENABLED_BUILDER_RECIPE)

    package = recipe.packages[0]
    assert package.builder_type == BuilderType.RUST
    assert package.builder_hashes.cargo_hash == "sha256-CARGO"


def test_unknown_builder_falls_back_to_standard(parse_recipe) -> None:
    recipe = parse_recipe(UNKNOWN_BUILDER_RECIPE)

    assert recipe.packages[0].builder_type == BuilderType.STANDARD


def test_url_source(parse_recipe) -> None:
    recipe = parse_recipe(URL_RECIPE)

    source = recipe.packages[0].source
    assert source.type == SourceType.URL
    assert source.url is not None
    assert source.url.url == "https://example.com/demo-1.2.3.tar.gz"


def test_path_source(parse_recipe) -> None:
    recipe = parse_recipe(PATH_RECIPE)

    source = recipe.packages[0].source
    assert source.type == SourceType.PATH
    assert source.path is not None
    assert source.path.path == Path("demo")


def test_missing_version_is_a_parse_error(parse_error) -> None:
    message = parse_error(MISSING_VERSION_RECIPE)

    assert "version field not found" in message


def test_missing_source_is_a_parse_error(parse_error) -> None:
    message = parse_error(MISSING_SOURCE_RECIPE)

    assert "no source (git/url/path) found" in message


def test_writer_records_old_and_new_values(parsed_basic) -> None:
    recipe = parsed_basic.recipe
    writer = RecipeWriter()

    writer.update_version(recipe, "demo", "2.0.0")
    writer.update_git_rev(recipe, "demo", "v2.0.0")

    assert writer.pending_changes == [
        ("version", "1.2.3", "2.0.0"),
        ("git", "github:example/demo/v1.2.3", "github:example/demo/v2.0.0"),
    ]


def test_replacing_a_missing_field_is_a_parse_error(parsed_basic) -> None:
    recipe = parsed_basic.recipe

    with pytest.raises(RecipeParseError) as err:
        RecipeWriter().update_cargo_hash(recipe, "demo", "sha256-new")

    assert "cannot find cargoHash for demo" in str(err.value)


def test_updating_a_missing_git_spec_is_a_parse_error(parse_recipe) -> None:
    recipe = parse_recipe(URL_RECIPE)

    with pytest.raises(RecipeParseError) as err:
        RecipeWriter().update_git_rev(recipe, "demo", "v2.0.0")

    assert "cannot find git spec for demo" in str(err.value)


def test_apply_text_respects_dry_run(parsed_basic, basic_recipe_text) -> None:
    writer = RecipeWriter(dry_run=True)
    writer.update_version(parsed_basic.recipe, "demo", "2.0.0")

    writer.apply_text(parsed_basic.recipe)

    assert parsed_basic.path.read_text() == basic_recipe_text


def test_apply_text_writes_changes(parsed_basic) -> None:
    writer = RecipeWriter()
    writer.update_version(parsed_basic.recipe, "demo", "2.0.0")

    writer.apply_text(parsed_basic.recipe)

    assert 'version = "2.0.0"' in parsed_basic.path.read_text()
