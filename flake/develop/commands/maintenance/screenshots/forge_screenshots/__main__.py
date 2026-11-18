"""forge-screenshots: configure and update application screenshots.

For each application, find screenshot URLs, download the images, convert them
to WebP files in a `screenshots` directory next to the recipe, and write a
`screenshots.nix` file that uses these files. A `screenshots.nix` file that
this command did not write stays as it is. Sources, in order:

1. AppStream metainfo files in the application packages. The packages are
   read from the local store or from a binary cache, without a build. If a
   package links desktop files or icons from other store paths (for example,
   a wrapper of an unwrapped package), the metainfo files of these store paths
   are also used.
2. AppStream metainfo files in the sources of the application packages. The
   sources are read from the local store or from a binary cache, or fetched
   with Nix.

If a source gives no image that can be fetched, the next source is used.

A URL of a file in a GitHub, GitLab, Forgejo or Gitea repository that is also
the source of an application package is changed to the URL of the file at the
revision of the source, so that the image matches the packaged version. If the
file is not at this revision, the URL stays as it is.

The URL and the hash of each original image are kept in a comment in
`screenshots.nix`. If they do not change, the files stay as they are.
"""

import argparse
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from . import log
from .commands import update
from .nix import nix
from .store import Store

# Applied to the `apps` output of the flake.
EVAL_FILE = Path(__file__).with_name("eval.nix")


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="forge-screenshots", description=(__doc__ or "").split("\n")[0]
    )
    parser.add_argument("apps", nargs="*", help="applications to update")
    parser.add_argument("--all", action="store_true", help="update all applications")
    parser.add_argument("--flake", default=".", help="flake to evaluate (default: .)")
    parser.add_argument(
        "--max", type=int, default=6, help="maximum screenshots per app (default: 6)"
    )
    parser.add_argument(
        "--jobs", type=int, default=8, help="applications to update in parallel"
    )
    parser.add_argument("--dry-run", action="store_true", help="do not write files")
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="print the steps for each application",
    )
    args = parser.parse_args()
    if not args.apps and not args.all:
        parser.print_help()
        sys.exit(0)
    if args.apps and args.all:
        parser.error("use either application names or `--all`")
    log.VERBOSE = args.verbose

    root = Path(
        subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
    )
    result = nix(
        "eval", "--json", f"{args.flake}#apps", "--apply", EVAL_FILE.read_text()
    )
    if result.returncode != 0:
        sys.exit(result.stderr.decode())
    apps: dict[str, dict] = json.loads(result.stdout)
    unknown = [name for name in args.apps if name not in apps]
    if unknown:
        sys.exit(f"unknown applications: {', '.join(unknown)}")
    names = args.apps or sorted(apps)

    store = Store()
    with ThreadPoolExecutor(max_workers=args.jobs) as executor:
        results = executor.map(
            lambda name: update(name, apps[name], store, root, args), names
        )
        for name, outcome in zip(names, results):
            print(f"{name}: {outcome}")


if __name__ == "__main__":
    main()
