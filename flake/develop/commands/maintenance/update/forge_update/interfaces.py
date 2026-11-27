"""Structural interfaces.

``main()`` takes its version detector and hash updater as keyword
arguments so tests can inject fakes without touching the real implementations.

These protocols define what such an object must look like and type checkers
verify this structurally (duck typing), but nothing is enforced at runtime.

Further reading:
- https://peps.python.org/pep-0544/ (Protocols: structural subtyping)
- https://docs.python.org/3/library/typing.html#typing.Protocol
- https://typing.python.org/en/latest/reference/protocols.html
"""

from typing import Protocol

from .recipe import RecipeWriter
from .types import PackageEntry, Recipe
from .version import VersionResult


class VersionDetector(Protocol):
    """Resolve the latest upstream version of a recipe.

    The concrete implementation is
    :class:`forge_update.version.GitVersionDetector`.
    """

    def detect(self, recipe: Recipe) -> VersionResult: ...


class NixHashUpdater(Protocol):
    """Rewrite recipe hashes by querying upstream builds.

    The concrete implementation is
    :class:`forge_update.builder.NixBuildHashUpdater`.
    """

    def update_source(
        self, recipe: Recipe, writer: RecipeWriter, pkg: PackageEntry
    ) -> None: ...

    def field_name(self, pkg: PackageEntry) -> str | None: ...

    def update(
        self, recipe: Recipe, writer: RecipeWriter, pkg: PackageEntry
    ) -> None: ...
