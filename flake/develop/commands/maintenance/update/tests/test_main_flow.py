"""Orchestration decision matrix for ``main()``.

Every test runs the real ``RecipeParser``/``RecipeWriter`` against temp files
and injects a fake ``VersionDetector``/``NixHashUpdater`` through ``main()``'s
keyword arguments.
"""

from pathlib import Path
from typing import NamedTuple

import pytest
from conftest import (
    BUMP,
    STANDARD_BUILDER,
    RecordingDetector,
    RecordingUpdater,
    git_recipe,
    path_recipe,
    url_recipe,
)

import forge_update.__main__ as main_module
from forge_update.errors import VersionDetectionError
from forge_update.types import Recipe, Source, SourceType
from forge_update.version import VersionResult

URL_RECIPE = url_recipe(builder=STANDARD_BUILDER)

PATH_RECIPE = path_recipe(builder=STANDARD_BUILDER)

SELF_REF_RECIPE = git_recipe(
    "github:example/demo/v${recipe.version}", builder=STANDARD_BUILDER
)

# With ``--version`` the detector never runs, so its result is irrelevant.
UNUSED_RESULT = VersionResult(version="unused", rev="unused")

MULTI_PACKAGE_RECIPE = """\
{
  pkgs.first = {
    version = "1.0.0";

    source = {
      git = "github:example/first/v1.0.0";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };

    build.builders.standard = {
      enable = true;
    };
  };

  pkgs.second = {
    version = "1.0.0";

    source = {
      git = "github:example/second/v1.0.0";
      hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";
    };

    build.builders.standard = {
      enable = true;
    };
  };
}
"""


class SequenceDetector(RecordingDetector):
    """Return (or raise) results in order, recording every call."""

    def __init__(self, results: list[VersionResult | Exception]) -> None:
        self.results = results
        self.calls: list[Recipe] = []

    def detect(self, recipe: Recipe) -> VersionResult:
        self.calls.append(recipe)
        result = self.results.pop(0)
        if isinstance(result, Exception):
            raise result
        return result


class FlowRun(NamedTuple):
    """The observable state after one ``main()`` run."""

    path: Path
    detector: RecordingDetector
    updater: RecordingUpdater
    code: int
    out: str
    err: str


@pytest.fixture
def run_update(make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text):
    """Write a recipe and run ``main()`` with injected fakes."""

    def _run(
        result: VersionResult | Exception = BUMP,
        args: tuple[str, ...] = ("demo",),
        *,
        text: str = basic_recipe_text,
        field: str | None = "cargoHash",
        detector: RecordingDetector | None = None,
        updater: RecordingUpdater | None = None,
        path: Path | None = None,
    ) -> FlowRun:
        if path is None:
            path = make_recipe("demo", text)
        if detector is None:
            detector = fake_detector(result)
        if updater is None:
            updater = fake_updater(field=field)
        code, out, err = run_main(list(args), detector=detector, hash_updater=updater)
        return FlowRun(path, detector, updater, code, out, err)

    return _run


def test_unchanged_recipe_is_noop(
    run_update, git_spy, assert_no_hash_calls, basic_recipe_text
):
    """Version and rev unchanged -> no write, no hash update, no git."""
    run = run_update(VersionResult(version="1.2.3", rev="v1.2.3"))

    assert run.code == 0
    assert "already at 1.2.3" in run.out
    assert run.path.read_text() == basic_recipe_text
    assert_no_hash_calls(run.updater)
    assert git_spy == []


def test_version_bump_only(run_update, basic_recipe_text):
    """Same rev, new version -> only the version line changes."""
    run = run_update(VersionResult(version="2.0.0", rev="v1.2.3"), field=None)

    expected = basic_recipe_text.replace('version = "1.2.3"', 'version = "2.0.0"')
    assert run.code == 0
    assert "+2.0.0" in run.out
    assert run.path.read_text() == expected
    assert 'git = "github:example/demo/v1.2.3"' in run.path.read_text()


def test_rev_bump_only(run_update, basic_recipe_text):
    """Same version, new rev -> only the git line changes."""
    run = run_update(VersionResult(version="1.2.3", rev="v2.0.0"), field=None)

    expected = basic_recipe_text.replace(
        "github:example/demo/v1.2.3", "github:example/demo/v2.0.0"
    )
    assert run.code == 0
    assert run.path.read_text() == expected


def test_version_and_rev_bump(run_update, basic_recipe_text):
    """Version and rev both change."""
    run = run_update(BUMP, field=None)

    expected = basic_recipe_text.replace(
        'version = "1.2.3"', 'version = "2.0.0"'
    ).replace("github:example/demo/v1.2.3", "github:example/demo/v2.0.0")
    assert run.code == 0
    assert run.path.read_text() == expected


def test_self_ref_updates_version_only_but_still_prefetches(run_update):
    """Self-ref rev is left alone, but hashes are still updated (D9)."""
    run = run_update(
        VersionResult(version="2.0.0", rev="v2.0.0", self_ref=True),
        text=SELF_REF_RECIPE,
        field="cargoHash",
    )

    expected = SELF_REF_RECIPE.replace('version = "1.2.3"', 'version = "2.0.0"')
    assert run.code == 0
    assert run.path.read_text() == expected
    assert 'git = "github:example/demo/v${recipe.version}"' in run.path.read_text()
    assert len(run.updater.source_calls) == 1
    assert len(run.updater.field_calls) == 1
    assert len(run.updater.update_calls) == 1


def test_self_ref_with_skip_prefetch_skips_hashes(run_update, assert_no_hash_calls):
    """Self-ref plus --skip-prefetch -> no hash updater calls at all."""
    run = run_update(
        VersionResult(version="2.0.0", rev="v2.0.0", self_ref=True),
        ("demo", "--skip-prefetch"),
        text=SELF_REF_RECIPE,
    )

    expected = SELF_REF_RECIPE.replace('version = "1.2.3"', 'version = "2.0.0"')
    assert run.code == 0
    assert run.path.read_text() == expected
    assert_no_hash_calls(run.updater)


def test_explicit_version_updates_without_detection(
    run_update, assert_no_hash_calls, basic_recipe_text
):
    """--version bypasses the detector and writes no rev."""
    run = run_update(
        UNUSED_RESULT,
        ("demo", "--version", "9.9.9"),
    )

    expected = basic_recipe_text.replace('version = "1.2.3"', 'version = "9.9.9"')
    assert run.code == 0
    assert run.path.read_text() == expected
    assert run.detector.calls == []
    assert_no_hash_calls(run.updater)


def test_url_source_with_explicit_version(run_update):
    """URL sources can be bumped with --version and never touch hashes."""
    run = run_update(args=("demo", "--version", "2.0.0"), text=URL_RECIPE)

    expected = URL_RECIPE.replace('version = "1.2.3"', 'version = "2.0.0"')
    assert run.code == 0
    assert run.path.read_text() == expected


def test_path_source_with_explicit_version(run_update):
    """PATH sources can be bumped with --version and never touch hashes."""
    run = run_update(args=("demo", "--version", "2.0.0"), text=PATH_RECIPE)

    expected = PATH_RECIPE.replace('version = "1.2.3"', 'version = "2.0.0"')
    assert run.code == 0
    assert run.path.read_text() == expected


def test_url_source_without_version_reports_error_and_continues(
    make_recipe, run_main, fake_updater, basic_recipe_text
):
    """An undetectable URL recipe fails cleanly; the next recipe still runs."""
    bad_path = make_recipe("bad", URL_RECIPE)
    good_path = make_recipe("good", basic_recipe_text)
    detector = SequenceDetector(
        [
            VersionDetectionError(
                Source(type=SourceType.URL),
                "URL sources not supported for auto-detection",
            ),
            BUMP,
        ]
    )

    code, out, _err = run_main(
        ["bad", "good"], detector=detector, hash_updater=fake_updater(field=None)
    )

    assert code == 0
    assert "bad" in out
    assert "Cannot detect version from URL" in out
    assert bad_path.read_text() == URL_RECIPE
    assert 'version = "2.0.0"' in good_path.read_text()


def test_dry_run_prints_without_writing(
    run_update, git_spy, assert_no_hash_calls, basic_recipe_text
):
    """--dry-run reports changes but leaves bytes and subprocesses alone."""
    run = run_update(args=("demo", "--dry-run", "--commit"))

    assert run.code == 0
    assert "+2.0.0" in run.out
    assert "+github:example/demo/v2.0.0" in run.out
    assert run.path.read_text() == basic_recipe_text
    assert_no_hash_calls(run.updater)
    assert git_spy == []


def test_skip_prefetch_writes_version_and_rev(
    run_update, assert_no_hash_calls, basic_recipe_text
):
    """--skip-prefetch still writes version and rev, but no hashes."""
    run = run_update(BUMP, ("demo", "--skip-prefetch"))

    expected = basic_recipe_text.replace(
        'version = "1.2.3"', 'version = "2.0.0"'
    ).replace("github:example/demo/v1.2.3", "github:example/demo/v2.0.0")
    assert run.code == 0
    assert run.path.read_text() == expected
    assert_no_hash_calls(run.updater)


def test_prefetch_updates_source_then_builder_hash(run_update):
    """Prefetch updates the source hash before the builder hash."""
    run = run_update(BUMP, field="cargoHash")

    assert run.code == 0
    assert run.updater.call_order == ["source", "field", "builder"]


def test_prefetch_without_builder_hash(run_update):
    """No builder hash field -> update_source runs, update does not."""
    run = run_update(BUMP, field=None)

    assert run.code == 0
    assert len(run.updater.source_calls) == 1
    assert len(run.updater.field_calls) == 1
    assert run.updater.update_calls == []


def test_empty_rev_skips_hash_updates(
    run_update, assert_no_hash_calls, basic_recipe_text
):
    """An empty rev disables prefetch even for a git source."""
    run = run_update(VersionResult(version="2.0.0", rev=""))

    expected = basic_recipe_text.replace('version = "1.2.3"', 'version = "2.0.0"')
    assert run.code == 0
    assert run.path.read_text() == expected
    assert 'git = "github:example/demo/v1.2.3"' in run.path.read_text()
    assert_no_hash_calls(run.updater)


def test_all_processes_recipes_in_sorted_order(
    make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text
):
    """--all sorts recipe names and separates their output."""
    for name in ("z", "a", "m"):
        _path = make_recipe(name, basic_recipe_text)

    detector = fake_detector(BUMP)

    code, out, _err = run_main(
        ["--all", "--skip-prefetch"], detector=detector, hash_updater=fake_updater()
    )

    assert code == 0
    assert [r.abs_path.parent.name for r in detector.calls] == ["a", "m", "z"]
    # Three reports are separated by one blank line each: 3 - 1 = 2.
    assert out.count("\n\n") == 2


def test_all_on_empty_root(recipes_root, run_main, fake_detector, fake_updater):
    """An empty root is a successful no-op."""
    detector = fake_detector(BUMP)

    code, out, _err = run_main(
        ["--all"], detector=detector, hash_updater=fake_updater()
    )

    assert code == 0
    assert out == ""
    assert detector.calls == []


def test_all_treats_plain_files_as_recipes(
    recipes_root, make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text
):
    """Non-directory entries are attempted as recipe names (current behavior)."""
    path = make_recipe("demo", basic_recipe_text)
    _stray = (recipes_root / "stray.txt").write_text("not a recipe")
    detector = fake_detector(BUMP)

    code, out, _err = run_main(
        ["--all", "--skip-prefetch"], detector=detector, hash_updater=fake_updater()
    )

    assert code == 0
    assert "Recipe 'stray.txt' not found" in out
    assert 'version = "2.0.0"' in path.read_text()


def test_prefetch_timeout_reaches_updater(
    make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text, monkeypatch
):
    """--prefetch-timeout is forwarded to NixBuildHashUpdater as an int."""
    _path = make_recipe("demo", basic_recipe_text)
    detector = fake_detector(BUMP)
    updater = fake_updater(field=None)
    captured = {}

    def factory(**kwargs):
        captured.update(kwargs)
        return updater

    monkeypatch.setattr(main_module, "NixBuildHashUpdater", factory)

    code, _out, _err = run_main(["demo", "--prefetch-timeout", "42"], detector=detector)

    assert code == 0
    assert captured == {"dry_run": False, "source_timeout": 42}


def test_only_first_package_is_updated(run_update):
    """Multi-package recipes only update packages[0] (current limitation)."""
    run = run_update(args=("demo", "--skip-prefetch"), text=MULTI_PACKAGE_RECIPE)

    text = run.path.read_text()
    assert run.code == 0
    assert text.count('version = "2.0.0"') == 1
    assert text.count('version = "1.0.0"') == 1
    assert "github:example/first/v2.0.0" in text
    assert "github:example/second/v1.0.0" in text


def test_second_run_is_noop(run_update, fake_detector, basic_recipe_text):
    """Rerunning with the same result leaves the file byte-identical."""
    detector = fake_detector(BUMP)

    first = run_update(BUMP, detector=detector, field=None)
    after_first = first.path.read_text()

    second = run_update(BUMP, detector=detector, field=None, path=first.path)

    assert second.code == 0
    assert "already at 2.0.0" in second.out
    assert second.path.read_text() == after_first
    assert len(detector.calls) == 2


def test_all_does_not_recurse(
    recipes_root, make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text
):
    """Nested recipe dirs are unreachable via --all (current limitation)."""
    path = make_recipe("demo", basic_recipe_text)
    nested = recipes_root / "container" / "inner"
    nested.mkdir(parents=True)
    nested_recipe = nested / "recipe.nix"
    _nested = nested_recipe.write_text(basic_recipe_text)
    detector = fake_detector(BUMP)

    code, out, _err = run_main(
        ["--all", "--skip-prefetch"], detector=detector, hash_updater=fake_updater()
    )

    assert code == 0
    assert "Recipe 'container' not found" in out
    assert 'version = "2.0.0"' in path.read_text()
    assert nested_recipe.read_text() == basic_recipe_text
