"""Failure recovery in ``main()``.

The contract pinned here: a failed recipe is reported on stdout and skipped,
the remaining recipes still run, and ``main()`` returns ``0`` regardless of
failures (current behavior; TODO: return ``1`` on failure).
"""

import hashlib
from pathlib import Path

import pytest
from conftest import BROKEN_RECIPE, BUMP, INHERITED_RECIPE

from forge_update.errors import BuildError
from forge_update.recipe import RecipeWriter
from forge_update.types import Recipe


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _line_index(lines: list[str], marker: str) -> int:
    """Index of the first output line containing ``marker``."""
    matches = [index for index, line in enumerate(lines) if marker in line]
    assert matches, f"no output line contains {marker!r}:\n" + "\n".join(lines)
    return matches[0]


@pytest.fixture
def record_writes(monkeypatch: pytest.MonkeyPatch) -> list[tuple[Path, str | None]]:
    """Record every ``RecipeWriter.apply_text`` call as ``(path, text)``."""
    writes: list[tuple[Path, str | None]] = []
    original_apply = RecipeWriter.apply_text

    def record(self: RecipeWriter, recipe: Recipe, text: str | None = None) -> None:
        writes.append((recipe.abs_path, text))
        original_apply(self, recipe, text)

    monkeypatch.setattr(RecipeWriter, "apply_text", record)
    return writes


def test_missing_recipe_prints_error_and_continues(
    recipes_root, make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text
) -> None:
    """A missing recipe is reported; the next recipe is still updated."""
    good = make_recipe("good", basic_recipe_text)
    detector = fake_detector(BUMP)
    updater = fake_updater()

    code, out, _err = run_main(
        ["missing", "good"], detector=detector, hash_updater=updater
    )

    expected_root = recipes_root.relative_to(Path.cwd())

    assert code == 0
    assert f"Recipe 'missing' not found in {expected_root}" in out
    assert 'version = "2.0.0"' in good.read_text()


def test_parse_error_is_reported(make_recipe, run_main, fake_updater) -> None:
    """A malformed recipe is reported and left byte-identical."""
    path = make_recipe("broken", BROKEN_RECIPE)

    code, out, _err = run_main(["broken"], hash_updater=fake_updater())

    expected_path = path.relative_to(Path.cwd())

    assert code == 0
    assert f"Failed to parse {expected_path}" in out
    assert "no package declarations found" in out
    assert path.read_text() == BROKEN_RECIPE


def test_inherited_recipe_unsupported(
    make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text
) -> None:
    """An inherited package is reported as unsupported; the run continues."""
    inherited = make_recipe("demo", INHERITED_RECIPE)
    good = make_recipe("good", basic_recipe_text)
    detector = fake_detector(BUMP)

    code, out, _err = run_main(
        ["demo", "good"], detector=detector, hash_updater=fake_updater()
    )

    assert code == 0
    assert (
        "'demo' cannot be auto-updated: package is inherited from another recipe" in out
    )
    assert inherited.read_text() == INHERITED_RECIPE
    assert 'version = "2.0.0"' in good.read_text()


def test_build_error_restores_original_bytes(
    make_recipe,
    run_main,
    fake_detector,
    fake_updater,
    basic_recipe_text,
    record_writes,
) -> None:
    """A ``BuildError`` writes the pre-update bytes back and is reported."""
    path = make_recipe("demo", basic_recipe_text)
    before = _sha256(path)

    detector = fake_detector(BUMP)
    updater = fake_updater(error=BuildError("demo", 1, "error: build failed"))

    code, out, _err = run_main(["demo"], detector=detector, hash_updater=updater)

    expected_writes = [(path.resolve(), basic_recipe_text)]
    recorded_writes = [(written.resolve(), text) for written, text in record_writes]

    # The failure is reported and only the source hash was attempted.
    assert code == 0
    assert "Build of 'demo' failed (exit 1)" in out
    assert "error: build failed" in out
    assert len(updater.source_calls) == 1

    # The file is byte-identical to before, restored by the recorded write.
    assert _sha256(path) == before
    assert path.read_text() == basic_recipe_text
    assert recorded_writes == expected_writes


def test_error_before_original_read_does_not_restore(
    recipes_root, run_main, fake_updater, record_writes
) -> None:
    """A missing recipe fails before parsing; no write is attempted."""
    code, out, _err = run_main(["missing"], hash_updater=fake_updater())

    assert code == 0
    assert "Recipe 'missing' not found" in out
    assert record_writes == []
    assert not (recipes_root / "missing").exists()


def test_commit_not_called_after_error(
    make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text, git_spy
) -> None:
    """``--commit`` never reaches git when the recipe fails."""
    _path = make_recipe("demo", basic_recipe_text)
    detector = fake_detector(BUMP)
    updater = fake_updater(error=BuildError("demo", 1, "boom"))

    code, out, _err = run_main(
        ["demo", "--commit"], detector=detector, hash_updater=updater
    )

    assert code == 0
    assert "Build of 'demo' failed (exit 1)" in out
    assert git_spy == []


def test_two_recipes_first_fails_second_succeeds(
    make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text
) -> None:
    """Output carries both names in order; only the second file is written."""
    broken = make_recipe("broken", BROKEN_RECIPE)
    good = make_recipe("good", basic_recipe_text)
    detector = fake_detector(BUMP)

    code, out, _err = run_main(
        ["broken", "good"], detector=detector, hash_updater=fake_updater()
    )

    assert code == 0
    lines = out.splitlines()
    failure_index = _line_index(lines, "Failed to parse")
    success_index = _line_index(lines, "+2.0.0")
    assert failure_index < success_index
    assert broken.read_text() == BROKEN_RECIPE
    assert 'version = "2.0.0"' in good.read_text()


def test_error_exit_code(run_main, fake_updater) -> None:
    """Failures still exit ``0``: pinned current behavior awaiting D2."""
    code, out, _err = run_main(["missing"], hash_updater=fake_updater())

    assert code == 0
    assert "Recipe 'missing' not found" in out
