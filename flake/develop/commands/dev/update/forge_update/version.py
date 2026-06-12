import datetime
import re
import subprocess
from dataclasses import dataclass

from . import regexes
from .errors import VersionDetectionError
from .types import GitSource, Recipe, Source, SourceType


@dataclass
class VersionResult:
    version: str
    rev: str


class VersionDetector:
    def detect(self, recipe: Recipe) -> VersionResult:
        source = recipe.packages[0].source

        match source.type:
            case SourceType.GIT if source.git is not None:
                return self._detect_from_git(source.git)
            case SourceType.URL:
                raise VersionDetectionError(
                    source, "URL sources not supported for auto-detection"
                )
            case SourceType.PATH:
                raise VersionDetectionError(
                    source, "PATH sources not supported for auto-detection"
                )
            case _:
                raise VersionDetectionError(source, "no git source found")

    def _detect_from_git(self, git_source: GitSource) -> VersionResult:
        if self._is_commit_hash(git_source.rev):
            return self._detect_hash_based(git_source)
        return self._detect_tag_based(git_source)

    @staticmethod
    def _extract_numeric_version(tag: str) -> str:
        match = re.search(regexes.NUMERIC_VERSION, tag)
        return match.group(1) if match else tag

    @staticmethod
    def _is_commit_hash(rev: str) -> bool:
        return bool(re.fullmatch(r"[0-9a-f]{40}", rev))

    def _detect_tag_based(self, git_source: GitSource) -> VersionResult:
        remote = git_source.remote_url
        if not remote:
            raise VersionDetectionError(
                Source(type=SourceType.GIT, git=git_source),
                f"no remote URL for {git_source.host.value} source",
            )

        raw_tags = self._fetch_tags(remote, git_source)
        version_tags = self._filter_version_tags(raw_tags)

        if not version_tags:
            raise VersionDetectionError(
                Source(type=SourceType.GIT, git=git_source),
                f"no version tags found at {remote}",
            )

        sorted_tags = self._sort_tags(version_tags)
        latest = sorted_tags[0]
        return VersionResult(version=self._extract_numeric_version(latest), rev=latest)

    def _detect_hash_based(self, git_source: GitSource) -> VersionResult:
        remote = git_source.remote_url
        if not remote:
            raise VersionDetectionError(
                Source(type=SourceType.GIT, git=git_source),
                f"no remote URL for {git_source.host.value} source",
            )

        latest_tag = self._get_latest_tag(remote, git_source)
        latest_hash = self._get_head_commit(remote, git_source)
        date = datetime.date.today().isoformat()
        version = f"{latest_tag.removeprefix('v')}-unstable-{date}"
        return VersionResult(version=version, rev=latest_hash)

    def _get_latest_tag(self, remote: str, git_source: GitSource) -> str:
        raw_tags = self._fetch_tags(remote, git_source)
        version_tags = self._filter_version_tags(raw_tags)
        if not version_tags:
            return "0"
        return self._sort_tags(version_tags)[0]

    @staticmethod
    def _filter_version_tags(tags: set[str]) -> list[str]:
        return [t for t in tags if len(re.findall(r"\d+", t)) >= 2]

    def _fetch_tags(self, remote: str, git_source: GitSource) -> set[str]:
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
        return self._parse_tags(result.stdout)

    def _get_head_commit(self, remote: str, git_source: GitSource) -> str:
        try:
            result = subprocess.run(
                ["git", "ls-remote", remote, "HEAD"],
                capture_output=True,
                text=True,
                timeout=30,
            )
            result.check_returncode()
        except subprocess.CalledProcessError as e:
            raise VersionDetectionError(
                Source(type=SourceType.GIT, git=git_source),
                f"git ls-remote HEAD failed (exit {e.returncode}): {(e.stderr or '').strip()}",
            )
        except subprocess.TimeoutExpired:
            raise VersionDetectionError(
                Source(type=SourceType.GIT, git=git_source),
                f"git ls-remote HEAD timed out for {remote}",
            )

        for line in result.stdout.splitlines():
            if "\t" not in line:
                continue
            sha, ref = line.split("\t", 1)
            if ref == "HEAD":
                return sha

        raise VersionDetectionError(
            Source(type=SourceType.GIT, git=git_source),
            f"no HEAD ref found at {remote}",
        )

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
        def key(tag: str) -> tuple[int, ...]:
            nums = re.findall(r"\d+", tag.removeprefix("v"))
            return tuple(int(n) for n in nums)

        return sorted(tags, key=key, reverse=True)
