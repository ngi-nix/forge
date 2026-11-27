"""Hash extraction in ``builder.py``.

The updater runs ``nix build`` and reads the hash out of the eventual
mismatch. These tests fake ``subprocess.run`` and use real temporary recipe
files, so no Nix is involved.
"""

import subprocess
from collections.abc import Callable
from pathlib import Path
from typing import NamedTuple

import pytest
from conftest import HASH, SubprocessCall, call_argv, call_kwargs

from forge_update.builder import NixBuildHashUpdater
from forge_update.errors import BuildError
from forge_update.recipe import RecipeWriter
from forge_update.types import (
    BuilderHashes,
    BuilderType,
    PackageEntry,
    Recipe,
    Source,
    SourceType,
)

CARGO_HASH = "sha256-OLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLDOLD="
NEW_HASH = "sha256-NEWNEWNEWNEWNEWNEWNEWNEWNEWNEWNEWNEWNEWNEWNEWNEW="

CARGO_RECIPE = f"""\
{{
  pkgs.demo = {{
    version = "1.2.3";

    source = {{
      git = "github:example/demo/v1.2.3";
      hash = "{HASH}";
    }};

    build.builders.rust = {{
      enable = true;
      cargoHash = "{CARGO_HASH}";
    }};
  }};
}}
"""


class CargoSetup(NamedTuple):
    """A parsed Cargo recipe plus a writer, ready for the updater."""

    path: Path
    original: str
    recipe: Recipe
    writer: RecipeWriter


def _package(
    builder_type: BuilderType, hashes: BuilderHashes | None = None
) -> PackageEntry:
    return PackageEntry(
        pname="demo",
        version="1.2.3",
        source=Source(type=SourceType.GIT),
        builder_type=builder_type,
        builder_hashes=hashes or BuilderHashes(),
    )


def _recipe_from(path: Path) -> Recipe:
    text = path.read_text()
    return Recipe(
        rel_path=path.parent,
        abs_path=path,
        raw_lines=text.splitlines(keepends=True),
    )


def _completed(returncode: int, stderr: str) -> subprocess.CompletedProcess[str]:
    return subprocess.CompletedProcess(
        args=["nix"], returncode=returncode, stdout="", stderr=stderr
    )


def _record(
    monkeypatch: pytest.MonkeyPatch, result: subprocess.CompletedProcess[str]
) -> list[SubprocessCall]:
    calls: list[SubprocessCall] = []

    def fake(*args: object, **kwargs: object) -> subprocess.CompletedProcess[str]:
        calls.append((args, kwargs))
        return result

    monkeypatch.setattr(subprocess, "run", fake)
    return calls


@pytest.fixture
def cargo_setup(make_recipe) -> CargoSetup:
    """Write ``CARGO_RECIPE`` and parse it into a fresh writer.

    The text carries a Cargo hash, but tests parametrized over other builders
    can still use it: behavior is driven by the package metadata, and the
    recipe only needs a field to edit.
    """
    path = make_recipe("demo", CARGO_RECIPE)
    return CargoSetup(path, path.read_text(), _recipe_from(path), RecipeWriter())


@pytest.fixture
def nix_must_not_run(
    subprocess_raises: Callable[[BaseException], None],
) -> None:
    """Fail the test if anything invokes ``nix build``."""
    subprocess_raises(AssertionError("nix build must not run"))


@pytest.mark.parametrize(
    ("builder_type", "hashes", "expected"),
    [
        (BuilderType.GO, BuilderHashes(vendor_hash="sha256-v"), "vendorHash"),
        (BuilderType.GO, BuilderHashes(), None),
        (BuilderType.RUST, BuilderHashes(), "cargoHash"),
        (BuilderType.NPM, BuilderHashes(), "npmDepsHash"),
        (BuilderType.PNPM, BuilderHashes(), "pnpmDepsHash"),
        (BuilderType.STANDARD, BuilderHashes(), None),
        (BuilderType.PYTHON, BuilderHashes(), None),
        (BuilderType.OCAML, BuilderHashes(), None),
        (BuilderType.PYTHON_MODULE, BuilderHashes(), None),
    ],
)
def test_field_name(
    builder_type: BuilderType, hashes: BuilderHashes, expected: str | None
) -> None:
    assert NixBuildHashUpdater().field_name(_package(builder_type, hashes)) == expected


@pytest.mark.usefixtures("nix_must_not_run")
@pytest.mark.parametrize(
    "builder_type",
    [
        BuilderType.GO,
        BuilderType.STANDARD,
        BuilderType.PYTHON,
        BuilderType.OCAML,
        BuilderType.PYTHON_MODULE,
    ],
)
def test_update_without_a_hash_is_a_noop(
    builder_type: BuilderType, cargo_setup: CargoSetup
) -> None:
    NixBuildHashUpdater().update(
        cargo_setup.recipe, cargo_setup.writer, _package(builder_type)
    )

    assert cargo_setup.writer.pending_changes == []
    assert cargo_setup.path.read_text() == cargo_setup.original


def test_update_source_reads_the_got_hash(
    cargo_setup: CargoSetup, monkeypatch: pytest.MonkeyPatch
) -> None:
    calls = _record(
        monkeypatch, _completed(1, f"error: mismatch\n  got:    {NEW_HASH}\n")
    )

    NixBuildHashUpdater(source_timeout=42).update_source(
        cargo_setup.recipe, cargo_setup.writer, _package(BuilderType.STANDARD)
    )

    assert cargo_setup.writer.pending_changes == [("source.hash", HASH, NEW_HASH)]
    assert call_argv(calls[0]) == ["nix", "build", ".#pkgs.demo.src", "--no-link"]
    assert call_kwargs(calls[0])["timeout"] == 42
    assert f'hash = "{NEW_HASH}"' in "".join(cargo_setup.recipe.raw_lines)
    assert cargo_setup.path.read_text() == cargo_setup.original


def test_update_rust_reads_the_cargo_hash(
    cargo_setup: CargoSetup, monkeypatch: pytest.MonkeyPatch
) -> None:
    calls = _record(monkeypatch, _completed(1, f"got: {NEW_HASH}\n"))
    pkg = _package(BuilderType.RUST, BuilderHashes(cargo_hash=CARGO_HASH))

    NixBuildHashUpdater().update(cargo_setup.recipe, cargo_setup.writer, pkg)

    assert cargo_setup.writer.pending_changes == [("cargoHash", CARGO_HASH, NEW_HASH)]
    assert call_argv(calls[0]) == ["nix", "build", ".#pkgs.demo", "--no-link"]
    # Ecosystem deps are not timed out; only source builds get the timeout.
    assert call_kwargs(calls[0])["timeout"] is None
    assert f'cargoHash = "{NEW_HASH}"' in "".join(cargo_setup.recipe.raw_lines)
    assert cargo_setup.path.read_text() == cargo_setup.original


def test_nonzero_return_code_is_accepted_when_the_hash_is_found(
    cargo_setup: CargoSetup, monkeypatch: pytest.MonkeyPatch
) -> None:
    _ = _record(monkeypatch, _completed(7, f"got: {NEW_HASH}\n"))

    NixBuildHashUpdater().update_source(
        cargo_setup.recipe, cargo_setup.writer, _package(BuilderType.STANDARD)
    )

    assert cargo_setup.writer.pending_changes == [("source.hash", HASH, NEW_HASH)]


def test_timeout_reports_exit_minus_one(
    cargo_setup: CargoSetup, subprocess_raises
) -> None:
    subprocess_raises(subprocess.TimeoutExpired(cmd="nix build", timeout=42))

    with pytest.raises(BuildError) as err:
        NixBuildHashUpdater(source_timeout=42).update_source(
            cargo_setup.recipe, cargo_setup.writer, _package(BuilderType.STANDARD)
        )

    assert err.value.exit_code == -1
    assert "timed out (42s)" in str(err.value)
    assert cargo_setup.path.read_text() == cargo_setup.original


def test_missing_got_hash_reports_the_stderr_tail(
    cargo_setup: CargoSetup, monkeypatch: pytest.MonkeyPatch
) -> None:
    stderr = "\n".join(f"err-{i:02d}" for i in range(25))
    _ = _record(monkeypatch, _completed(2, stderr))

    with pytest.raises(BuildError) as err:
        NixBuildHashUpdater().update_source(
            cargo_setup.recipe, cargo_setup.writer, _package(BuilderType.STANDARD)
        )

    message = str(err.value)
    assert "exit 2" in message
    # ``BuildError`` keeps the last 20 stderr lines, so err-04 falls off the
    # front and err-05 is the oldest line still shown.
    assert "err-24" in message
    assert "err-05" in message
    assert "err-04" not in message
    assert cargo_setup.path.read_text() == cargo_setup.original


@pytest.mark.usefixtures("nix_must_not_run")
def test_dry_run_never_runs_nix(cargo_setup: CargoSetup) -> None:
    NixBuildHashUpdater(dry_run=True).update_source(
        cargo_setup.recipe, cargo_setup.writer, _package(BuilderType.STANDARD)
    )

    assert cargo_setup.writer.pending_changes == []
    assert cargo_setup.path.read_text() == cargo_setup.original
