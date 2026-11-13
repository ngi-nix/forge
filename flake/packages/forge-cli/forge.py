#!/usr/bin/env python3
"""
Evaluate, build, run or enter a shell of a Forge application with its
parameters set.
"""

import json
import os
import shlex
import shutil
import sys
from typing import NoReturn

# Nix expression evaluated by `nix`, with the arguments from the command line.
EXPR = "@expr@"

USAGE = """\
Usage: forge <eval|build|run|shell> <app>[.<output>] [--set <name>=<value>]... [-v] [-- <nix options>]

Run, build, evaluate or enter a shell of an application, with its parameters set.

Options:
  --set <name>=<value>  Set the parameter <name> of the application.
  -v, --verbose         Print the nix command before running it.
  -h, --help            Print this help.

Examples:
  forge run livebook.container --set port=9090
  forge build livebook.vm --set port=9090
  forge eval livebook.config.parameters --set port=9090 -- --json
  forge shell livebook --set port=9090
"""


def fail(message: str) -> NoReturn:
    sys.exit(f"forge: {message}")


def fail_usage() -> NoReturn:
    sys.stderr.write(USAGE)
    sys.exit(1)


def main(args):
    if args[:1] in (["-h"], ["--help"]):
        print(USAGE, end="")
        return
    if len(args) < 2 or args[0] not in ("run", "build", "eval", "shell"):
        fail_usage()
    command, target, rest = args[0], args[1], args[2:]
    app, _, output = target.partition(".")

    parameters = {}
    nix_options = []
    verbose = False
    while rest:
        option = rest.pop(0)
        if option == "--set":
            name, equals, value = (rest.pop(0) if rest else "").partition("=")
            if not name or not equals:
                fail("use --set <name>=<value>")
            parameters[name] = value
        elif option in ("-v", "--verbose"):
            verbose = True
        elif option == "--":
            nix_options = rest
            break
        elif option in ("-h", "--help"):
            print(USAGE, end="")
            return
        else:
            sys.stderr.write(f"forge: unknown option '{option}'\n")
            fail_usage()

    nix = shutil.which("nix")
    if nix is None:
        fail("cannot find nix")
    with open(EXPR) as file:
        expr = file.read()
    # `nix` passes the `--argstr` arguments only when an attribute is
    # selected, hence `result`. The values of the parameters stay strings;
    # `expr` converts them to the types of the parameters in the recipe.
    nix_args = [
        "result",
        "--argstr", "app", app,
        "--argstr", "output", output,
        "--argstr", "parameters", json.dumps(parameters),
        *nix_options,
    ]  # fmt: skip
    if verbose:
        # The expression is long, so print it as the file that contains it.
        print(
            f'nix {command} --expr "$(cat {EXPR})" {shlex.join(nix_args)}',
            file=sys.stderr,
        )
    os.execv(nix, ["nix", command, "--expr", expr, *nix_args])


if __name__ == "__main__":
    main(sys.argv[1:])
