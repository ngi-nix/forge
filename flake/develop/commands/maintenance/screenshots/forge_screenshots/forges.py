import re

REF = r"(?:refs/(?:heads|tags)/[^/]+|[^/]+)"
# The URLs of a file in a Git repository: the URL pattern, the URL of the
# repository, and the URL of the file at a revision. In the URL of the file,
# `rev` is the revision of the source, `ref` is the revision without
# `refs/heads/` or `refs/tags/`, and `kind` is "commit", "branch" or "tag". The
# first pattern that matches is used.
FORGE_FILES = [
    # GitHub.
    (
        re.compile(
            rf"https://raw\.githubusercontent\.com/(?P<repo>[^/]+/[^/]+)/{REF}/(?P<path>.+)"
        ),
        "https://github.com/{repo}",
        "https://raw.githubusercontent.com/{repo}/{rev}/{path}",
    ),
    (
        re.compile(
            rf"(?P<repo>https://github\.com/[^/]+/[^/]+)/raw/{REF}/(?P<path>.+)"
        ),
        "{repo}",
        "{repo}/raw/{rev}/{path}",
    ),
    # Forgejo and Gitea, for example Codeberg.
    (
        re.compile(
            r"(?P<repo>https://[^/]+/[^/]+/[^/]+)/raw/(?:branch|tag|commit)/[^/]+/(?P<path>.+)"
        ),
        "{repo}",
        "{repo}/raw/{kind}/{ref}/{path}",
    ),
    # GitLab. It does not find `refs/heads/<branch>` or `refs/tags/<tag>`.
    (
        re.compile(rf"(?P<repo>https://[^/]+/.+?)/-/raw/{REF}/(?P<path>.+)"),
        "{repo}",
        "{repo}/-/raw/{ref}/{path}",
    ),
    # Old GitLab URLs, without `-/`.
    (
        re.compile(rf"(?P<repo>https://gitlab\.[^/]+/.+?)/raw/{REF}/(?P<path>.+)"),
        "{repo}",
        "{repo}/-/raw/{ref}/{path}",
    ),
]
COMMIT = re.compile(r"[0-9a-f]{40}|[0-9a-f]{64}")


def repo_key(url: str) -> str:
    return url.removesuffix("/").removesuffix(".git").lower()


def source_revisions(sources: list[dict]) -> dict[str, str]:
    """Return the revisions of the sources, by `repo_key` of the Git repository."""
    revisions: dict[str, str] = {}
    for source in sources:
        if source["gitRepoUrl"] and source["rev"]:
            revisions.setdefault(repo_key(source["gitRepoUrl"]), source["rev"])
    return revisions


def pinned(url: str, revisions: dict[str, str]) -> str:
    """Return the URL of the file `url` at the revision of its source."""
    for pattern, repo, template in FORGE_FILES:
        match = pattern.fullmatch(url)
        if not match:
            continue
        parts = match.groupdict()
        rev = revisions.get(repo_key(repo.format(**parts)))
        if not rev:
            return url
        if COMMIT.fullmatch(rev):
            kind = "commit"
        elif rev.startswith("refs/heads/"):
            kind = "branch"
        else:
            kind = "tag"
        ref = re.sub(r"^refs/(?:heads|tags)/", "", rev)
        return template.format(**parts, rev=rev, ref=ref, kind=kind)
    return url
