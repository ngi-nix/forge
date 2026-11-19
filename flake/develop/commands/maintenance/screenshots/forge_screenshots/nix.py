import re
import subprocess


def last_line(output: bytes) -> str:
    """Return the last line of the output of a command, usually the error."""
    lines = output.decode().strip().splitlines()
    return lines[-1] if lines else "unknown error"


def nix(*args: str) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(["nix", *args], capture_output=True)


def nix_string(value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"').replace("${", "\\${")
    return f'"{escaped}"'


def nix_attr(name: str) -> str:
    return name if re.fullmatch(r"[a-zA-Z_][a-zA-Z0-9_'-]*", name) else nix_string(name)
