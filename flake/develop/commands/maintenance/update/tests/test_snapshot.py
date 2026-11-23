"""Byte-level snapshots of whole recipes after an update.

Each fixture is copied into a temporary recipe root and updated through ``main()``.
The resulting file is compared as a whole, so string-surgery regressions show up
as a readable diff instead of a single failed field.

``--skip-prefetch`` keeps every case hermetic: hashes are never recomputed,
so only the version and git lines can move.

Regenerate snapshots after an intentional change:

    pytest tests/test_snapshot.py --snapshot-update

Review the ``.ambr`` diff and commit it together with the change that caused
it. Never enable ``--snapshot-update`` in CI or ``addopts``.
"""

from pathlib import Path
from typing import Callable, NamedTuple

import pytest
from conftest import RecordingUpdater

from forge_update.version import VersionResult

FIXTURES = Path(__file__).parent / "fixtures" / "recipes"

TARGET = VersionResult(version="9.9.9", rev="v9.9.9")
SELF_REF_TARGET = VersionResult(version="9.9.9", rev="v9.9.9", self_ref=True)


class SnapshotRun(NamedTuple):
    """A fixture recipe after one update, plus the run's observable output."""

    path: Path
    before: str
    after: str
    updater: RecordingUpdater
    code: int
    out: str
    err: str


@pytest.fixture
def fixture_recipe() -> Callable[[str], str]:
    """Read one of the snapshot fixture recipes by case name."""

    def _read(name: str) -> str:
        return (FIXTURES / name / "recipe.nix").read_text()

    return _read


@pytest.fixture
def snapshot_run(make_recipe, run_main, fake_detector, fake_updater, fixture_recipe):
    """Write a fixture recipe, update it with ``TARGET``, and return the result."""

    def _run(
        name: str,
        *args: str,
        result: VersionResult = TARGET,
        prepare: Callable[[str], str] | None = None,
        path_name: str | None = None,
        hash_updater: RecordingUpdater | None = None,
    ) -> SnapshotRun:
        before = fixture_recipe(name)
        if prepare is not None:
            before = prepare(before)

        recipe_name = path_name or name
        path = make_recipe(recipe_name, before)
        updater = hash_updater or fake_updater()

        code, out, err = run_main(
            [recipe_name, *args, "--skip-prefetch"],
            detector=fake_detector(result),
            hash_updater=updater,
        )
        return SnapshotRun(path, before, path.read_text(), updater, code, out, err)

    return _run


@pytest.mark.parametrize(
    ("name", "result", "short_circuits"),
    [
        pytest.param("basic", TARGET, True, id="basic"),
        pytest.param("generic_git", TARGET, True, id="generic-git"),
        # Its git spec has no ``tag=``/``rev=`` to read back, so the parsed rev
        # stays ``HEAD`` and every run looks like a rev change.
        pytest.param("generic_git_bare", TARGET, False, id="generic-git-bare"),
        pytest.param("rust", TARGET, True, id="rust"),
        pytest.param("go", TARGET, True, id="go"),
        pytest.param("nested", TARGET, True, id="nested"),
        pytest.param("multi_package", TARGET, True, id="multi-package"),
        pytest.param("self_ref", SELF_REF_TARGET, True, id="self-ref"),
    ],
)
def test_snapshot_update(
    name: str,
    result: VersionResult,
    short_circuits: bool,
    snapshot_run,
    run_main,
    fake_detector,
    fake_updater,
    snapshot,
) -> None:
    """A detected version/rev rewrites exactly the expected lines."""
    run = snapshot_run(name, result=result)

    assert run.code == 0
    assert run.err == ""
    assert run.after != run.before
    assert run.after.endswith("\n")
    assert run.after == snapshot(name=f"recipe-{name}")

    # One replacement only: the target version appears once in the file, so
    # nested scripts and sibling packages cannot have been touched.
    assert run.after.count('version = "9.9.9"') == 1
    assert run.updater.source_calls == []
    assert run.updater.update_calls == []

    # The same detector result leaves the bytes untouched. Most cases also take
    # the "already at" short-circuit; ``generic_git_bare`` cannot, because its
    # git spec has no ``tag=``/``rev=`` to parse back, so the rev always looks
    # changed and the already-correct file is rewritten. That is byte-stable,
    # but not a true no-op.
    code, out, err = run_main(
        [name, "--skip-prefetch"],
        detector=fake_detector(result),
        hash_updater=fake_updater(),
    )
    assert code == 0
    assert err == ""
    assert run.path.read_text() == run.after
    assert ("already at 9.9.9" in out) is short_circuits


def test_snapshot_generic_git_preserves_query_parameters(snapshot_run) -> None:
    """Only the ``tag=`` value moves; other query parameters stay put."""
    run = snapshot_run("generic_git")

    assert "?tag=v9.9.9&depth=1" in run.after
    assert "?tag=v1.2.3" not in run.after


def test_snapshot_generic_git_bare_keeps_git_line(snapshot_run) -> None:
    """A generic git spec without ``tag=``/``rev=`` is rewritten as-is."""
    run = snapshot_run("generic_git_bare")

    assert 'git = "git:https://example.com/generic-git-bare.git"' in run.after
    assert 'version = "9.9.9"' in run.after


def test_snapshot_self_ref_leaves_git_line_untouched(snapshot_run) -> None:
    """A self-referencing rev is updated through ``version``, not ``git``."""
    run = snapshot_run("self_ref", result=SELF_REF_TARGET)

    assert 'git = "github:example/self-ref/v${recipe.version}"' in run.after
    assert "v9.9.9" not in run.after


def test_snapshot_multi_package_keeps_second_block(snapshot_run) -> None:
    """Only ``packages[0]`` is rewritten; the second block keeps its bytes."""
    run = snapshot_run("multi_package")

    assert 'version = "9.9.9"' in run.after
    assert 'version = "4.5.6"' in run.after
    assert 'git = "github:example/b/v4.5.6"' in run.after


def test_snapshot_nested_keeps_script_literal(snapshot_run) -> None:
    """A ``version = "1.2.3"`` literal inside ``test.script`` is not rewritten."""
    run = snapshot_run("nested")

    assert "echo 'version = \"1.2.3\"'" in run.after
    assert "cmakeFlags" in run.after
    assert "build.phases = {" in run.after


def test_snapshot_preserves_missing_trailing_newline(snapshot_run) -> None:
    """Updates never add a trailing newline that the recipe did not have."""
    run = snapshot_run(
        "basic",
        path_name="no-newline",
        prepare=lambda text: text.rstrip("\n"),
    )

    assert not run.after.endswith("\n")
    assert run.after.endswith("}")
    assert 'version = "9.9.9"' in run.after


def test_snapshot_url_version_only(
    snapshot_run, assert_no_hash_calls, snapshot
) -> None:
    """``--version`` updates a URL recipe without touching its hash."""
    run = snapshot_run("url", "--version", "9.9.9")

    assert run.code == 0
    assert run.err == ""
    assert run.after.endswith("\n")
    assert run.after == snapshot(name="recipe-url-version-only")
    assert 'url = "https://example.com/url-1.2.3.tar.gz"' in run.after
    assert 'hash = "sha256-LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL="' in run.after
    assert_no_hash_calls(run.updater)
