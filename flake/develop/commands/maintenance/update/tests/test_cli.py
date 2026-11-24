"""Argument parsing and terminal output in ``__main__.py``.

These tests call ``main()``/``parse_args()`` directly and inspect what is
printed; recipe updating itself is covered by the other test modules.
"""

import sys
from pathlib import Path

import pytest
from colorama import Fore, Style

import forge_update.__main__ as main_module
from forge_update.recipe import RecipeWriter

SCRIPT_SUCCESS_STATUS = 0
ARGPARSE_EXIT_STATUS = 2


def test_no_args_prints_help(capsys):
    argv = []

    with pytest.raises(SystemExit) as err:
        main_module.main(argv)

    assert err.value.code == SCRIPT_SUCCESS_STATUS

    captured = capsys.readouterr()

    assert "usage:" in captured.out
    # Pins the exact help text; the check above states the intent if argparse
    # formatting ever changes.
    assert captured.out == main_module.build_parser().format_help()


def test_all_with_recipe_names_errors(capsys):
    argv = ["offen", "--all"]

    with pytest.raises(SystemExit) as err:
        main_module.main(argv)

    assert err.value.code == ARGPARSE_EXIT_STATUS

    captured = capsys.readouterr()

    assert "--all cannot be used with recipe names" in captured.err


def test_parse_args_defaults():
    argv = []
    args = main_module.parse_args(argv)

    assert args.recipe == []
    assert args.all is False
    assert args.version is None
    assert args.dry_run is False
    assert args.commit is False
    assert args.skip_prefetch is False
    assert args.prefetch_timeout == 180
    assert args.recipes_root == Path("recipes/pkgs")


def test_parse_args_recipes_root_is_path():
    argv = ["--recipes-root", "some/recipes"]
    args = main_module.parse_args(argv)

    assert args.recipes_root == Path("some/recipes")


def test_parse_args_prefetch_timeout_is_int():
    argv = ["--prefetch-timeout", "42"]
    args = main_module.parse_args(argv)

    assert args.prefetch_timeout == 42


def test_parse_args_multiple_recipes():
    argv = ["foo", "bar", "baz"]
    args = main_module.parse_args(argv)

    assert args.recipe == ["foo", "bar", "baz"]


def test_parse_args_commit_boolean_optional():
    argv = []
    args = main_module.parse_args(argv)
    assert args.commit is False

    argv = ["--commit"]
    args = main_module.parse_args(argv)
    assert args.commit is True

    argv = ["--no-commit"]
    args = main_module.parse_args(argv)
    assert args.commit is False


@pytest.mark.parametrize(
    ("tty", "no_color", "styled"),
    [
        pytest.param(False, False, False, id="not-a-tty"),
        pytest.param(True, False, True, id="tty"),
        pytest.param(True, True, False, id="no-color-wins"),
    ],
)
def test_style(monkeypatch, tty, no_color, styled):
    monkeypatch.setattr(sys.stdout, "isatty", lambda: tty)
    monkeypatch.delenv("NO_COLOR", raising=False)

    if no_color:
        monkeypatch.setenv("NO_COLOR", "1")

    result = main_module.style("text", Fore.RED)

    if styled:
        assert result.startswith(Fore.RED)
        assert result.endswith(Style.RESET_ALL)
    else:
        assert result == "text"


def test_print_changes(capsys):
    writer = RecipeWriter()
    writer.pending_changes = [("version", "1.0", "2.0")]

    main_module._print_changes(writer, 0)

    captured = capsys.readouterr()

    # Two-space heading, then four-space old/new lines, one per line.
    assert captured.out == "  version\n    -1.0\n    +2.0\n"


def test_progress_clears_line(capsys):
    with main_module._progress("source.hash"):
        pass

    captured = capsys.readouterr()

    assert "source.hash (in progress)\r" in captured.out
    # Carriage return plus the ANSI erase-line sequence (ESC[K).
    assert "\r\033[K" in captured.out
