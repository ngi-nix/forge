import json

from .forges import pinned
from .log import info, warn
from .nix import last_line, nix
from .types import Screenshot


def is_image(head: bytes) -> bool:
    return head.startswith((b"\x89PNG", b"\xff\xd8\xff", b"GIF8")) or (
        head[:4] == b"RIFF" and head[8:12] == b"WEBP"
    )


class FetchError(Exception):
    pass


def fetch(url: str) -> tuple[str, str]:
    """Download the image at `url`, and return its SRI hash and its store path."""
    result = nix(
        "store",
        "prefetch-file",
        "--json",
        "--hash-type",
        "sha256",
        "--name",
        "screenshot",
        url,
    )
    if result.returncode != 0:
        raise FetchError(f"cannot fetch ({last_line(result.stderr)})")
    prefetched = json.loads(result.stdout)
    with open(prefetched["storePath"], "rb") as f:
        if not is_image(f.read(12)):
            raise FetchError("not a PNG, JPEG, GIF or WebP image")
    return prefetched["hash"], prefetched["storePath"]


def download(
    screenshots: list[Screenshot], maximum: int, revisions: dict[str, str]
) -> list[Screenshot]:
    """Download at most `maximum` of `screenshots`, and return them."""
    downloaded = []
    for screenshot in screenshots:
        if len(downloaded) >= maximum:
            break
        if not screenshot.url.startswith("https://"):
            warn(f"not an HTTPS URL: {screenshot.url}")
            continue
        # Prefer the file at the revision of the source, if it is there.
        urls = dict.fromkeys([pinned(screenshot.url, revisions), screenshot.url])
        problem = ""
        for url in urls:
            try:
                screenshot.hash, screenshot.path = fetch(url)
            except FetchError as e:
                problem = str(e)
                continue
            if url != screenshot.url:
                info(
                    f"using {url} instead of {screenshot.url},"
                    " because it is at the revision of the package source"
                )
                screenshot.url = url
            break
        else:
            warn(f"{problem}: {screenshot.url}")
            continue
        info(f"downloaded {screenshot.url} (hash {screenshot.hash})")
        downloaded.append(screenshot)
    return downloaded
