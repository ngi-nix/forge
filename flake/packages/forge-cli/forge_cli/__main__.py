"""
Evaluate, build, run or enter a shell of a Forge application with its
parameters set.
"""

import argparse
import sys

from . import log
from .commands import run

EXAMPLES = """\
examples:
  forge run livebook.container --set port=9090
  forge build livebook.vm --set port=9090
  forge eval livebook.config.parameters --set port=9090 -- --json
  forge shell livebook --set port=9090
"""


def parameter(option: str) -> tuple[str, str]:
    name, equals, value = option.partition("=")
    if not name or not equals:
        raise argparse.ArgumentTypeError("expected <name>=<value>")
    return name, value


def main() -> None:
    # Split the options for `nix` off before parsing, so that they are passed
    # as they are, even when they look like options of `forge`.
    args = sys.argv[1:]
    nix_options = []
    if "--" in args:
        separator = args.index("--")
        args, nix_options = args[:separator], args[separator + 1 :]

    parser = argparse.ArgumentParser(
        prog="forge",
        usage="%(prog)s {eval,build,run,shell} <app>[.<output>]"
        " [--set <name>=<value>]... [-v] [-- <nix options>]",
        description="Run, build, evaluate or enter a shell of an application,"
        " with its parameters set.",
        epilog=EXAMPLES,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "command",
        choices=["eval", "build", "run", "shell"],
        help="Nix command to run.",
    )
    parser.add_argument(
        "target",
        metavar="<app>[.<output>]",
        help="Application and its output.",
    )
    parser.add_argument(
        "--set",
        dest="parameters",
        action="append",
        default=[],
        type=parameter,
        metavar="<name>=<value>",
        help="Set the parameter <name> of the application.",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="store_true",
        help="Print the nix command before running it.",
    )
    if not args:
        parser.print_help(sys.stderr)
        sys.exit(1)
    parsed = parser.parse_args(args)
    log.set_verbose(parsed.verbose)

    app, _, output = parsed.target.partition(".")
    run(parsed.command, app, output, dict(parsed.parameters), nix_options)


if __name__ == "__main__":
    main()
