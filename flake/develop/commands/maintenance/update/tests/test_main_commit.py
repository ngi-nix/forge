"""The commit path of ``main()``.

Every test spies on ``subprocess.run`` and examines the recorded git commands
instead of executing them.
"""

import subprocess
from pathlib import Path
from typing import NamedTuple

import pytest
from conftest import BUMP, SubprocessCall, call_argv, call_kwargs

from forge_update.version import VersionResult


class CommitRun(NamedTuple):
    """The observable state after one commit-path run."""

    path: Path
    code: int
    out: str
    err: str


@pytest.fixture
def commit_run(make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text):
    """Write the basic recipe and run ``main()`` on it."""

    def _run(
        result: VersionResult | Exception = BUMP,
        args: tuple[str, ...] = ("demo", "--commit", "--skip-prefetch"),
    ) -> CommitRun:
        path = make_recipe("demo", basic_recipe_text)
        code, out, err = run_main(
            list(args), detector=fake_detector(result), hash_updater=fake_updater()
        )
        return CommitRun(path, code, out, err)

    return _run


def test_commit_stages_and_commits(commit_run, git_spy: list[SubprocessCall]) -> None:
    """A written recipe is staged, then committed, in that order."""
    run = commit_run()

    staged = str(run.path.relative_to(Path.cwd()))

    assert run.code == 0
    assert run.err == ""
    assert "committed" in run.out
    assert len(git_spy) == 2
    assert call_argv(git_spy[0]) == ["git", "add", staged]
    assert call_kwargs(git_spy[0]) == {"check": True, "capture_output": True}
    assert call_argv(git_spy[1]) == [
        "git",
        "commit",
        "-m",
        "recipes(pkgs.demo): 1.2.3 -> 2.0.0",
    ]
    assert call_kwargs(git_spy[1]) == {"check": True, "capture_output": True}


def test_no_commit_by_default(commit_run, git_spy: list[SubprocessCall]) -> None:
    """Without ``--commit`` the writer never invokes git."""
    run = commit_run(args=("demo", "--skip-prefetch"))

    assert run.code == 0
    assert "committed" not in run.out
    assert git_spy == []


def test_dry_run_never_commits(
    commit_run, git_spy: list[SubprocessCall], basic_recipe_text: str
) -> None:
    """``--dry-run`` suppresses both the write and the commit."""
    run = commit_run(args=("demo", "--commit", "--dry-run", "--skip-prefetch"))

    assert run.code == 0
    assert "committed" not in run.out
    assert run.path.read_text() == basic_recipe_text
    assert git_spy == []


def test_unchanged_recipe_never_commits(
    commit_run, git_spy: list[SubprocessCall], basic_recipe_text: str
) -> None:
    """No version or rev change means no write and no commit."""
    run = commit_run(VersionResult(version="1.2.3", rev="v1.2.3"))

    assert run.code == 0
    assert "already at 1.2.3" in run.out
    assert run.path.read_text() == basic_recipe_text
    assert git_spy == []


def test_commit_message_uses_old_version(
    commit_run, git_spy: list[SubprocessCall]
) -> None:
    """The subject pairs the parsed old version with the new one."""
    _run = commit_run(VersionResult(version="9.9.9", rev="v9.9.9"))

    assert len(git_spy) == 2
    assert call_argv(git_spy[1]) == [
        "git",
        "commit",
        "-m",
        "recipes(pkgs.demo): 1.2.3 -> 9.9.9",
    ]


def test_git_failure_is_handled(
    make_recipe, run_main, fake_detector, fake_updater, basic_recipe_text, monkeypatch
) -> None:
    """A failing ``git add`` escapes after the recipe was already written.

    Cannot use ``commit_run``: this test replaces ``subprocess.run`` with a
    raising fake *before* running ``main()``.
    """
    path = make_recipe("demo", basic_recipe_text)

    calls: list[SubprocessCall] = []

    def explode(*args: object, **kwargs: object) -> None:
        calls.append((args, kwargs))
        raise subprocess.CalledProcessError(1, "git")

    monkeypatch.setattr(subprocess, "run", explode)

    detector = fake_detector(BUMP)

    with pytest.raises(subprocess.CalledProcessError):
        _ = run_main(
            ["demo", "--commit", "--skip-prefetch"],
            detector=detector,
            hash_updater=fake_updater(),
        )

    assert len(calls) == 1
    assert call_argv(calls[0]) == [
        "git",
        "add",
        str(path.relative_to(Path.cwd())),
    ]
    assert 'version = "2.0.0"' in path.read_text()


@pytest.mark.git
def test_commit_smoke_real_repo(
    git_repo: Path, run_main, fake_detector, fake_updater
) -> None:
    """A real temporary repository records the expected commit subject.

    Runs in the default suite; it skips only when ``git`` is unavailable, since
    ``addopts`` does not exclude the ``git`` marker.
    """
    detector = fake_detector(BUMP)

    code, out, _err = run_main(
        ["demo", "--commit", "--skip-prefetch"],
        detector=detector,
        hash_updater=fake_updater(),
    )

    subject = subprocess.run(
        ["git", "log", "-1", "--format=%s"],
        cwd=git_repo,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()

    assert code == 0
    assert "committed" in out
    assert subject == "recipes(pkgs.demo): 1.2.3 -> 2.0.0"
