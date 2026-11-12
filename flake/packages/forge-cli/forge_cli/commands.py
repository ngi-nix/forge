import json
import os
import shlex
from typing import NoReturn

from .log import fail, info
from .nix import find_nix


def run(
    command: str,
    app: str,
    output: str,
    parameters: dict[str, str],
    nix_options: list[str],
) -> NoReturn:
    nix = find_nix()
    # File with the Nix expression that `nix` evaluates, with the arguments
    # from the command line. The wrapper of the package sets it.
    expr_file = os.environ.get("FORGE_EXPR")
    if expr_file is None:
        fail("FORGE_EXPR is not set")
    with open(expr_file) as file:
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
    # The expression is long, so print it as the file that contains it.
    info(f'nix {command} --expr "$(cat {expr_file})" {shlex.join(nix_args)}')
    os.execv(nix, ["nix", command, "--expr", expr, *nix_args])
