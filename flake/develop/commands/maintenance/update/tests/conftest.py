"""Shared fixtures for the ``forge_update`` test suite.

The suite exercises the real :class:`RecipeParser` and :class:`RecipeWriter`
against temporary files. Only the external boundaries are faked:
``VersionDetector`` and ``NixHashUpdater`` are injected through ``main()``'s
keyword arguments, so no class monkeypatching is required.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path
from typing import Callable, Protocol, cast

import pytest

import forge_update.__main__ as main_module
from forge_update.recipe import RecipeWriter
from forge_update.types import PackageEntry, Recipe
from forge_update.version import VersionResult

HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

# The canonical "bump" result shared by tests that only need a new version/rev.
BUMP = VersionResult(version="2.0.0", rev="v2.0.0")

BROKEN_RECIPE = "this is not a recipe\n"

INHERITED_RECIPE = """\
{
  pkgs.demo = {
    inherit (config.pkgs.other) version;
  };
}
"""

# A minimal, realistic GitHub tag recipe. Kept as a module constant so tests
# can assert against the exact bytes that were written.
BASIC_RECIPE = f"""\
{{
  pkgs.demo = {{
    version = "1.2.3";

    homePage = "https://example.com/demo";
    license = {{
      spdx = "MIT";
      fullText = "MIT License";
    }};

    source = {{
      git = "github:example/demo/v1.2.3";
      hash = "{HASH}";
    }};

    build.builders.standard = {{
      enable = true;
      description = "Demo package";
    }};

    meta.mainProgram = "demo";
  }};
}}
"""


# The standard builder block used by the orchestration tests. The leading
# blank line separates it from the source block, matching their layout.
STANDARD_BUILDER = """\

    build.builders.standard = {
      enable = true;
    };
"""


def git_recipe(
    git: str = "github:owner/repo/v1.2.3",
    *,
    version: str = "1.2.3",
    hash: str = HASH,
    submodules: bool = False,
    builder: str = "",
) -> str:
    """Render a one-package recipe with a git source.

    ``builder`` is inserted verbatim between the source block and the closing
    braces, for tests that need an extra builder section.
    """
    submodules_line = "      submodules = true;\n" if submodules else ""
    return f"""\
{{
  pkgs.demo = {{
    version = "{version}";
    source = {{
      git = "{git}";
      hash = "{hash}";
{submodules_line}    }};
{builder}  }};
}}
"""


def url_recipe(
    url: str = "https://example.com/demo-1.2.3.tar.gz",
    *,
    version: str = "1.2.3",
    hash: str = HASH,
    builder: str = "",
) -> str:
    """Render a one-package recipe with a URL source."""
    return f"""\
{{
  pkgs.demo = {{
    version = "{version}";
    source = {{
      url = "{url}";
      hash = "{hash}";
    }};
{builder}  }};
}}
"""


def path_recipe(
    path: str = "./demo",
    *,
    version: str = "1.2.3",
    builder: str = "",
) -> str:
    """Render a one-package recipe with a local path source."""
    return f"""\
{{
  pkgs.demo = {{
    version = "{version}";
    source.path = {path};
{builder}  }};
}}
"""


class RecordingDetector(Protocol):
    """The detector members tests inspect."""

    calls: list[Recipe]

    def detect(self, recipe: Recipe) -> VersionResult: ...


class RecordingUpdater(Protocol):
    """The updater members tests inspect."""

    source_calls: list[tuple[Recipe, PackageEntry]]
    field_calls: list[PackageEntry]
    update_calls: list[tuple[Recipe, PackageEntry]]
    call_order: list[str]


class FakeVersionDetector(RecordingDetector):
    """Record ``detect`` calls and return (or raise) a fixed result."""

    def __init__(self, result: VersionResult | Exception) -> None:
        self.result = result
        self.calls: list[Recipe] = []

    def detect(self, recipe: Recipe) -> VersionResult:
        self.calls.append(recipe)
        if isinstance(self.result, Exception):
            raise self.result
        return self.result


class FakeHashUpdater(RecordingUpdater):
    """Record hash-update calls; optionally raise during ``update_source``.

    The ``writer`` arguments match the real updater's interface but are
    ignored: this fake records calls instead of rewriting the recipe.
    """

    def __init__(
        self,
        field: str | None = "cargoHash",
        *,
        error: Exception | None = None,
    ) -> None:
        self.field = field
        self.error = error
        self.source_calls: list[tuple[Recipe, PackageEntry]] = []
        self.update_calls: list[tuple[Recipe, PackageEntry]] = []
        self.field_calls: list[PackageEntry] = []
        # The order in which ``main()`` reached each updater method.
        self.call_order: list[str] = []

    def update_source(
        self, recipe: Recipe, writer: RecipeWriter, pkg: PackageEntry
    ) -> None:
        self.source_calls.append((recipe, pkg))
        self.call_order.append("source")
        if self.error is not None:
            raise self.error

    def field_name(self, pkg: PackageEntry) -> str | None:
        self.field_calls.append(pkg)
        self.call_order.append("field")
        return self.field

    def update(self, recipe: Recipe, writer: RecipeWriter, pkg: PackageEntry) -> None:
        self.update_calls.append((recipe, pkg))
        self.call_order.append("builder")


@pytest.fixture
def recipes_root(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> Path:
    """Create ``<tmp>/recipes/pkgs`` and run the test from ``<tmp>``."""
    root = tmp_path / "recipes" / "pkgs"
    root.mkdir(parents=True)
    monkeypatch.chdir(tmp_path)
    return root


@pytest.fixture
def make_recipe(recipes_root: Path) -> Callable[[str, str], Path]:
    """Write ``<root>/<name>/recipe.nix`` and return its path."""

    def _make(name: str, text: str) -> Path:
        recipe_dir = recipes_root / name
        recipe_dir.mkdir(parents=True, exist_ok=True)
        path = recipe_dir / "recipe.nix"
        _ = path.write_text(text)
        return path

    return _make


@pytest.fixture
def basic_recipe_text() -> str:
    return BASIC_RECIPE


@pytest.fixture
def fake_detector() -> Callable[[VersionResult | Exception], FakeVersionDetector]:
    """Factory for a recording detector with a fixed result."""

    def _make(result: VersionResult | Exception) -> FakeVersionDetector:
        return FakeVersionDetector(result)

    return _make


@pytest.fixture
def fake_updater() -> Callable[..., FakeHashUpdater]:
    """Factory for a recording hash updater."""

    def _make(
        field: str | None = "cargoHash", *, error: Exception | None = None
    ) -> FakeHashUpdater:
        return FakeHashUpdater(field, error=error)

    return _make


@pytest.fixture
def run_main(
    capsys: pytest.CaptureFixture[str],
) -> Callable[..., tuple[int, str, str]]:
    """Run ``main()`` with injected fakes, normalizing exit styles.

    ``main()`` raises ``SystemExit`` for the no-args and ``--all`` conflict
    paths, but returns an ``int`` otherwise. This helper collapses both into a
    single exit code.
    """

    def _run(
        argv: list[str],
        *,
        detector: FakeVersionDetector | None = None,
        hash_updater: FakeHashUpdater | None = None,
    ) -> tuple[int, str, str]:
        try:
            code = main_module.main(argv, detector=detector, hash_updater=hash_updater)
        except SystemExit as exc:
            code = exc.code if isinstance(exc.code, int) else 0
        captured = capsys.readouterr()
        return code, captured.out, captured.err

    return _run


@pytest.fixture(autouse=True)
def stable_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """Force plain, width-stable output for every test."""
    monkeypatch.setenv("NO_COLOR", "1")
    monkeypatch.setenv("COLUMNS", "80")
    monkeypatch.setattr(sys.stdout, "isatty", lambda: False)


# One recorded ``subprocess.run`` invocation: args and kwargs.
SubprocessCall = tuple[tuple[object, ...], dict[str, object]]


def call_argv(call: SubprocessCall) -> list[str]:
    """Return the command list of one recorded ``subprocess.run`` call.

    The spy stores each call as ``(args, kwargs)``, so the command is the
    first positional argument (e.g. ``["git", "add", <path>]``).

    The ``cast`` is only for the type checker: the recorder declares its
    positional arguments as ``object``, while every call site passes a
    ``list[str]``.
    """
    args, _kwargs = call
    return cast(list[str], args[0])


def call_kwargs(call: SubprocessCall) -> dict[str, object]:
    """Return the keyword arguments of one recorded ``subprocess.run`` call."""
    _args, kwargs = call
    return kwargs


@pytest.fixture
def git_spy(monkeypatch: pytest.MonkeyPatch) -> list[SubprocessCall]:
    """Replace ``subprocess.run`` with a recorder; return its call log.

    Nothing is executed: each call is appended as ``(args, kwargs)``, so
    tests can assert on the commands or on the log. For example,
    when ``main()`` must not touch git, the log should be empty.

    Note that the patch is global for all ``subprocess`` use in the test.
    """
    calls: list[SubprocessCall] = []

    def record(*args: object, **kwargs: object) -> None:
        calls.append((args, kwargs))

    monkeypatch.setattr(subprocess, "run", record)
    return calls


@pytest.fixture
def git_repo(tmp_path: Path, make_recipe: Callable[[str, str], Path]) -> Path:
    """A temporary git repository with one committed recipe."""
    if shutil.which("git") is None:
        pytest.skip("git is not available")

    recipe = make_recipe("demo", BASIC_RECIPE)

    def git(*args: str) -> None:
        subprocess.run(
            ["git", *args],
            cwd=tmp_path,
            check=True,
            capture_output=True,
            text=True,
        )

    git("init", "-q")
    git("config", "user.name", "forge tests")
    git("config", "user.email", "tests@example.invalid")
    git("config", "commit.gpgsign", "false")
    git("add", str(recipe.relative_to(tmp_path)))
    git("commit", "-q", "-m", "initial")
    return tmp_path


@pytest.fixture
def assert_no_hash_calls() -> Callable[[FakeHashUpdater], None]:
    """Assert an updater was never asked to touch source or builder hashes."""

    def _assert(updater: FakeHashUpdater) -> None:
        assert updater.source_calls == []
        assert updater.update_calls == []

    return _assert


@pytest.fixture
def subprocess_raises(
    monkeypatch: pytest.MonkeyPatch,
) -> Callable[[BaseException], None]:
    """Replace ``subprocess.run`` with a caller that raises ``exc``."""

    def _raises(exc: BaseException) -> None:
        def fail(*_args: object, **_kwargs: object) -> object:
            raise exc

        monkeypatch.setattr(subprocess, "run", fail)

    return _raises


@pytest.fixture
def subprocess_returns(
    monkeypatch: pytest.MonkeyPatch,
) -> Callable[[subprocess.CompletedProcess[str]], None]:
    """Replace ``subprocess.run`` with a caller that returns ``result``."""

    def _returns(result: subprocess.CompletedProcess[str]) -> None:
        def fake(*_args: object, **_kwargs: object) -> subprocess.CompletedProcess[str]:
            return result

        monkeypatch.setattr(subprocess, "run", fake)

    return _returns
