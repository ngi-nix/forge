import re
import subprocess

from packaging.version import InvalidVersion, Version

from .errors import VersionDetectionError
from .types import GitSource, Recipe, Source, SourceType


class VersionDetector:
    def detect(self, recipe: Recipe, explicit_version: str | None = None) -> str:
        if explicit_version is not None:
            return explicit_version

        source = recipe.packages[0].source

        if source.type == SourceType.GIT and source.git is not None:
            return self._detect_from_git(source.git)
        elif source.type == SourceType.URL:
            raise VersionDetectionError(
                source, "URL sources not supported for auto-detection"
            )
        elif source.type == SourceType.PATH:
            raise VersionDetectionError(
                source, "PATH sources not supported for auto-detection"
            )

        raise VersionDetectionError(source, "no git source found")

    def _detect_from_git(self, git_source: GitSource) -> str:
        remote = git_source.remote_url
        if not remote:
            raise VersionDetectionError(
                Source(type=SourceType.GIT, git=git_source),
                f"no remote URL for {git_source.host.value} source",
            )

        try:
            result = subprocess.run(
                ["git", "ls-remote", "--tags", remote],
                capture_output=True,
                text=True,
                timeout=30,
            )
            result.check_returncode()
        except subprocess.CalledProcessError as e:
            raise VersionDetectionError(
                Source(type=SourceType.GIT, git=git_source),
                f"git ls-remote failed (exit {e.returncode}): {(e.stderr or '').strip()}",
            )
        except subprocess.TimeoutExpired:
            raise VersionDetectionError(
                Source(type=SourceType.GIT, git=git_source),
                f"git ls-remote timed out for {remote}",
            )

        raw_tags = self._parse_tags(result.stdout)
        version_tags = [t for t in raw_tags if re.search(r"\d", t)]

        if not version_tags:
            raise VersionDetectionError(
                Source(type=SourceType.GIT, git=git_source),
                f"no version tags found at {remote}",
            )

        sorted_tags = self._sort_tags(version_tags)
        latest = sorted_tags[0]
        return latest.removeprefix("v")

    @staticmethod
    def _parse_tags(raw: str) -> set[str]:
        tags: set[str] = set()
        for line in raw.splitlines():
            if "\t" not in line:
                continue
            _, ref = line.split("\t", 1)
            if ref.startswith("refs/tags/"):
                tag = ref.removeprefix("refs/tags/")
                tag = tag.removesuffix("^{}")
                tags.add(tag)
        return tags

    @staticmethod
    def _sort_tags(tags: list[str]) -> list[str]:
        def key(tag: str) -> tuple[int, Version | str]:
            stripped = tag.removeprefix("v")
            try:
                return (1, Version(stripped))
            except InvalidVersion:
                return (0, tag)

        return sorted(tags, key=key, reverse=True)
