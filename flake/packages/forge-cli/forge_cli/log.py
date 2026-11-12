import sys
from typing import NoReturn

_verbose = False


def set_verbose(verbose: bool) -> None:
    global _verbose
    _verbose = verbose


def info(message: str) -> None:
    if _verbose:
        print(message, file=sys.stderr)


def fail(message: str) -> NoReturn:
    sys.exit(f"forge: {message}")
