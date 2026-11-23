"""Pure tag and version logic in ``version.py``.

No network and no real repository: tag lists, process results, and commit
hashes are supplied directly. ``subprocess.run`` is faked only on the error
paths.
"""

# The unit tests below call the detector's private helpers on purpose.
# pyright: reportPrivateUsage=false

import subprocess
from pathlib import Path
from typing import Callable

import pytest
from conftest import BUMP

from forge_update.errors import VersionDetectionError
from forge_update.types import (
    BuilderType,
    ForgeHost,
    GitSource,
    PackageEntry,
    PathSource,
    Recipe,
    Source,
    SourceType,
    UrlSource,
)
from forge_update.version import GitVersionDetector, VersionResult

COMMIT = "0123456789abcdef0123456789abcdef01234567"
REMOTE = "https://example.com/owner/repo"
COMMIT_DATE = "2025-01-02"
UNSTABLE_VERSION = f"0-unstable-{COMMIT_DATE}"


def _git_source(rev: str, *, host: ForgeHost = ForgeHost.GENERIC_GIT) -> GitSource:
    return GitSource(
        host=host,
        owner="owner",
        repo="repo",
        rev=rev,
        remote_url=REMOTE,
    )


def _recipe(version: str, source: Source) -> Recipe:
    package = PackageEntry(
        pname="demo",
        version=version,
        source=source,
        builder_type=BuilderType.STANDARD,
    )
    return Recipe(
        rel_path=Path("demo"),
        abs_path=Path("recipes/pkgs/demo/recipe.nix"),
        packages=[package],
    )


def _git_recipe(
    version: str, rev: str, *, host: ForgeHost = ForgeHost.GENERIC_GIT
) -> Recipe:
    return _recipe(
        version, Source(type=SourceType.GIT, git=_git_source(rev, host=host))
    )


def _fix_tags(
    monkeypatch: pytest.MonkeyPatch, detector: GitVersionDetector, tags: set[str]
) -> None:
    def fake(_remote: str, _git_source: GitSource) -> set[str]:
        return tags

    monkeypatch.setattr(detector, "_fetch_tags", fake)


@pytest.fixture
def detector() -> GitVersionDetector:
    return GitVersionDetector()


@pytest.fixture
def hash_detector(
    monkeypatch: pytest.MonkeyPatch,
) -> Callable[[set[str]], GitVersionDetector]:
    """Build a detector with fake tags, head commit, and commit date."""

    def _make(tags: set[str]) -> GitVersionDetector:
        detector = GitVersionDetector()
        _fix_tags(monkeypatch, detector, tags)
        monkeypatch.setattr(
            detector, "_get_head_commit", lambda _remote, _source: COMMIT
        )
        monkeypatch.setattr(
            detector, "_get_commit_date", lambda _source, _commit: COMMIT_DATE
        )
        return detector

    return _make


@pytest.mark.parametrize(
    ("tag", "expected"),
    [
        ("v1.2.3", "1.2.3"),
        ("1.10.0", "1.10.0"),
        ("sequoia-sq/v1.5.0", "1.5.0"),
        ("release_1.2.3-rc.1+build.5", "1.2.3"),
        ("not-a-version", "not-a-version"),
    ],
)
def test_extract_numeric_version(tag: str, expected: str) -> None:
    assert GitVersionDetector._extract_numeric_version(tag) == expected


@pytest.mark.parametrize("tag", ["node-redis_v18-7", "v1.2.3.beta", "1.2.3rc1"])
def test_non_version_tags_are_left_untouched(tag: str) -> None:
    assert GitVersionDetector._extract_numeric_version(tag) == tag


@pytest.mark.parametrize(
    ("rev", "expected"),
    [
        (COMMIT, True),
        (COMMIT[:-1], False),
        (COMMIT + "a", False),
        (COMMIT.upper(), False),
        (COMMIT[:-1] + "g", False),
    ],
)
def test_is_commit_hash(rev: str, expected: bool) -> None:
    assert GitVersionDetector._is_commit_hash(rev) is expected


@pytest.mark.parametrize(
    ("version", "expected"),
    [
        ("1.0.0-rc.1", True),
        ("1.0.0-beta", True),
        ("v2.0.0-SNAPSHOT", True),
        ("1.0.0+m1", False),
        ("1.0.0-1", False),
        ("1.0.0-esp32", False),
        ("1.0.0-prefix", False),
        ("1.0.0", False),
    ],
)
def test_is_prerelease(version: str, expected: bool) -> None:
    assert GitVersionDetector._is_prerelease(version) is expected


def test_filter_version_tags_keeps_only_versions() -> None:
    tags = {"v1.0.0", "v2.0.0-rc.1", "nightly", "node-redis_v18-7", "1.2.3"}

    filtered = GitVersionDetector._filter_version_tags(tags)

    assert set(filtered) == {"v1.0.0", "v2.0.0-rc.1", "1.2.3"}


def test_sort_tags_orders_numerically(detector: GitVersionDetector) -> None:
    assert detector._sort_tags(["v1.9.0", "v1.10.0"]) == ["v1.10.0", "v1.9.0"]


def test_sort_tags_prefers_stable_over_prerelease(
    detector: GitVersionDetector,
) -> None:
    assert detector._sort_tags(["v2.0.0-rc.1", "v2.0.0"]) == [
        "v2.0.0",
        "v2.0.0-rc.1",
    ]


def test_sort_tags_handles_deep_versions(detector: GitVersionDetector) -> None:
    assert detector._sort_tags(["v1.2.3", "v1.2.3.4"]) == ["v1.2.3.4", "v1.2.3"]


def test_sort_tags_requires_version_tags(detector: GitVersionDetector) -> None:
    # ``_sort_tags`` guards its precondition with ``assert``; callers must
    # filter with ``_filter_version_tags`` first. Disappears under ``-O``.
    with pytest.raises(AssertionError):
        _ = detector._sort_tags(["nightly"])


def test_parse_tags_dedupes_peeled_and_plain_refs() -> None:
    raw = "\n".join(
        [
            "aaa\trefs/tags/v1.0.0",
            "bbb\trefs/tags/v1.0.0^{}",
            "ccc\trefs/heads/main",
            "malformed line",
            "ddd\trefs/tags/v2.0.0",
        ]
    )

    assert GitVersionDetector._parse_tags(raw) == {"v1.0.0", "v2.0.0"}


def test_tag_based_prerelease_current_considers_every_tag(
    monkeypatch: pytest.MonkeyPatch, detector: GitVersionDetector
) -> None:
    _fix_tags(monkeypatch, detector, {"v1.0.0-rc.1", "v2.0.0-beta", "v1.9.0"})

    result = detector._detect_tag_based(_git_source("v1.0.0-rc.1"), "1.0.0-rc.1")

    assert result == VersionResult(version="2.0.0", rev="v2.0.0-beta")


def test_tag_based_stable_current_skips_prereleases(
    monkeypatch: pytest.MonkeyPatch, detector: GitVersionDetector
) -> None:
    _fix_tags(monkeypatch, detector, {"v1.0.0", "v2.0.0-rc.1"})

    result = detector._detect_tag_based(_git_source("v1.0.0"), "1.0.0")

    assert result == VersionResult(version="1.0.0", rev="v1.0.0")


def test_tag_based_without_stable_tags_mentions_version_flag(
    monkeypatch: pytest.MonkeyPatch, detector: GitVersionDetector
) -> None:
    _fix_tags(
        monkeypatch,
        detector,
        {"v4.0.0-rc.1", "v3.0.0-rc.1", "v2.0.0-rc.1", "v1.0.0-rc.1"},
    )

    with pytest.raises(VersionDetectionError) as err:
        _ = detector._detect_tag_based(_git_source("v1.0.0"), "1.0.0")

    message = str(err.value)
    assert f"no stable version tags found at {REMOTE}" in message
    assert "only pre-releases: v4.0.0-rc.1, v3.0.0-rc.1, v2.0.0-rc.1" in message
    assert "v1.0.0-rc.1" not in message
    assert "use --version to pin one explicitly" in message


def test_tag_based_without_version_tags_reports_remote(
    monkeypatch: pytest.MonkeyPatch, detector: GitVersionDetector
) -> None:
    _fix_tags(monkeypatch, detector, {"nightly", "latest"})

    with pytest.raises(VersionDetectionError) as err:
        _ = detector._detect_tag_based(_git_source("v1.0.0"), "1.0.0")

    assert f"no version tags found at {REMOTE}" in str(err.value)


def test_hash_based_builds_unstable_version(hash_detector) -> None:
    detector = hash_detector({"v1.2.3"})

    result = detector._detect_hash_based(_git_source(COMMIT))

    assert result == VersionResult(
        version=f"1.2.3-unstable-{COMMIT_DATE}",
        rev=COMMIT,
    )


def test_hash_based_without_tags_uses_zero(hash_detector) -> None:
    detector = hash_detector(set())

    result = detector._detect_hash_based(_git_source(COMMIT))

    assert result.version == UNSTABLE_VERSION


def test_detect_routes_commit_hash_revs_to_hash_detection(
    monkeypatch: pytest.MonkeyPatch, detector: GitVersionDetector
) -> None:
    calls: list[GitSource] = []

    def fake(git_source: GitSource) -> VersionResult:
        calls.append(git_source)
        return VersionResult(version=UNSTABLE_VERSION, rev=COMMIT)

    monkeypatch.setattr(detector, "_detect_hash_based", fake)

    result = detector.detect(_git_recipe("0-unstable-2024-01-01", COMMIT))

    assert result == VersionResult(version=UNSTABLE_VERSION, rev=COMMIT)
    assert len(calls) == 1


def test_detect_routes_tag_revs_to_tag_detection(
    monkeypatch: pytest.MonkeyPatch, detector: GitVersionDetector
) -> None:
    calls: list[tuple[GitSource, str]] = []

    def fake(git_source: GitSource, current_version: str) -> VersionResult:
        calls.append((git_source, current_version))
        return BUMP

    monkeypatch.setattr(detector, "_detect_tag_based", fake)

    result = detector.detect(_git_recipe("1.2.3", "v1.2.3"))

    assert result == BUMP
    assert calls[0][1] == "1.2.3"


def test_detect_marks_self_ref_revs(
    monkeypatch: pytest.MonkeyPatch, detector: GitVersionDetector
) -> None:
    def fake(_git_source: GitSource, _current_version: str) -> VersionResult:
        return BUMP

    monkeypatch.setattr(detector, "_detect_tag_based", fake)

    result = detector.detect(_git_recipe("1.2.3", "v${recipe.version}"))

    assert result == VersionResult(version="2.0.0", rev="v2.0.0", self_ref=True)


@pytest.mark.parametrize(
    ("source", "detail"),
    [
        (
            Source(type=SourceType.URL, url=UrlSource(url="https://example.com/x")),
            "URL sources not supported",
        ),
        (
            Source(type=SourceType.PATH, path=PathSource(path=Path("./demo"))),
            "PATH sources not supported",
        ),
    ],
    ids=["url", "path"],
)
def test_detect_rejects_non_git_sources(
    detector: GitVersionDetector, source: Source, detail: str
) -> None:
    with pytest.raises(VersionDetectionError) as err:
        _ = detector.detect(_recipe("1.2.3", source))

    assert detail in str(err.value)


def test_fetch_tags_wraps_called_process_error(
    detector: GitVersionDetector, subprocess_raises
) -> None:
    subprocess_raises(
        subprocess.CalledProcessError(128, ["git", "ls-remote"], stderr="down")
    )

    with pytest.raises(VersionDetectionError) as err:
        _ = detector._fetch_tags(REMOTE, _git_source(COMMIT))

    assert "git ls-remote failed (exit 128): down" in str(err.value)


def test_fetch_tags_reports_timeout(
    detector: GitVersionDetector, subprocess_raises
) -> None:
    subprocess_raises(subprocess.TimeoutExpired(cmd="git", timeout=30))

    with pytest.raises(VersionDetectionError) as err:
        _ = detector._fetch_tags(REMOTE, _git_source(COMMIT))

    assert f"git ls-remote timed out for {REMOTE}" in str(err.value)


def test_head_commit_returns_the_head_sha(
    detector: GitVersionDetector, subprocess_returns
) -> None:
    subprocess_returns(
        subprocess.CompletedProcess(args=[], returncode=0, stdout=f"{COMMIT}\tHEAD\n")
    )

    assert detector._get_head_commit(REMOTE, _git_source(COMMIT)) == COMMIT


def test_head_commit_without_head_ref_reports_remote(
    detector: GitVersionDetector, subprocess_returns
) -> None:
    subprocess_returns(
        subprocess.CompletedProcess(
            args=[], returncode=0, stdout="aaa\trefs/heads/main\n"
        )
    )

    with pytest.raises(VersionDetectionError) as err:
        _ = detector._get_head_commit(REMOTE, _git_source(COMMIT))

    assert f"no HEAD ref found at {REMOTE}" in str(err.value)


def test_head_commit_wraps_called_process_error(
    detector: GitVersionDetector, subprocess_raises
) -> None:
    subprocess_raises(
        subprocess.CalledProcessError(1, ["git", "ls-remote"], stderr="boom")
    )

    with pytest.raises(VersionDetectionError) as err:
        _ = detector._get_head_commit(REMOTE, _git_source(COMMIT))

    assert "git ls-remote HEAD failed (exit 1): boom" in str(err.value)
