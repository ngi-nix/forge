import argparse
import subprocess
from pathlib import Path

from .fetch import download
from .forges import source_revisions
from .log import info, set_app
from .metainfo import candidates
from .nix import last_line
from .render import GENERATED, SCREENSHOTS_DIR, SOURCE_LINE, render, write
from .store import Store

# The flake does not allow unfree applications, so their configuration is not
# available.
UNFREE = "skipped (unfree application)"


def update(
    name: str, app: dict, store: Store, root: Path, args: argparse.Namespace
) -> str:
    set_app(name)
    if app.get("unfree"):
        return UNFREE
    target = root / Path(app["recipePath"]).parent / "screenshots.nix"
    info(f"`{target.relative_to(root)}`")
    existing = target.read_text() if target.exists() else ""
    if existing and not existing.startswith(GENERATED):
        return "kept (`screenshots.nix` is not from this command)"
    revisions = source_revisions(app["sources"])
    for source, screenshots in candidates(name, app, store):
        downloaded = download(screenshots, args.max, revisions)
        if not downloaded:
            continue
        content = render(name, source, downloaded)
        files = [
            target.with_name(SCREENSHOTS_DIR) / f"{index}.webp"
            for index in range(len(downloaded))
        ]
        # The package and its source often have the same screenshots. Thus,
        # if only the source changes, do not change the files.
        if SOURCE_LINE.sub("", existing) == SOURCE_LINE.sub("", content) and all(
            file.is_file() for file in files
        ):
            return f"unchanged ({source})"
        if args.dry_run:
            return f"would update ({source})"
        try:
            write(target, content, downloaded)
        except subprocess.CalledProcessError as e:
            return f"not updated (cannot convert an image: {last_line(e.stderr)})"
        return f"updated ({source})"
    return "no screenshots found"
