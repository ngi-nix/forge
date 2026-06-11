from dataclasses import dataclass, field
from enum import Enum, auto
from pathlib import Path


class SourceType(Enum):
    GIT = auto()
    URL = auto()
    PATH = auto()


class BuilderType(Enum):
    STANDARD = auto()
    RUST = auto()
    GO = auto()
    NPM = auto()
    PNPM = auto()
    PYTHON_APP = auto()
    PYTHON_PACKAGE = auto()


class ForgeHost(Enum):
    GITHUB = "github"
    GITLAB = "gitlab"
    CODEBERG = "codeberg"
    FORGEJO = "forgejo"
    GITEA = "gitea"
    GENERIC_GIT = "git"


@dataclass
class GitSource:
    host: ForgeHost
    owner: str
    repo: str
    rev: str
    remote_url: str = ""
    submodules: bool = False


@dataclass
class UrlSource:
    url: str


@dataclass
class PathSource:
    path: Path


@dataclass
class Source:
    type: SourceType
    git: GitSource | None = None
    url: UrlSource | None = None
    path: PathSource | None = None
    hash: str = ""


@dataclass
class BuilderHashes:
    cargo_hash: str | None = None
    vendor_hash: str | None = None
    npm_deps_hash: str | None = None
    pnpm_deps_hash: str | None = None


@dataclass
class PackageEntry:
    """A single package declared within a recipe.nix file."""

    pname: str
    version: str
    source: Source
    builder_type: BuilderType
    builder_hashes: BuilderHashes = field(default_factory=BuilderHashes)


@dataclass
class Recipe:
    """A recipe.nix file, which may declare one or more packages."""

    rel_path: Path
    abs_path: Path
    raw_lines: list[str] = field(default_factory=list)
    packages: list[PackageEntry] = field(default_factory=list)
