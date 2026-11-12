import shutil

from .log import fail


def find_nix() -> str:
    nix = shutil.which("nix")
    if nix is None:
        fail("cannot find nix")
    return nix
