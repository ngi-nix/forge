import sys
import threading

_verbose = False
# The application that the current thread updates or checks, for `info`.
_current = threading.local()


def _prefix() -> str:
    """Return `[<app>] `, to tell the steps apart from the result lines."""
    app = getattr(_current, "app", "")
    return f"[{app}] " if app else ""


def warn(message: str) -> None:
    print(f"{_prefix()}warning: {message}", file=sys.stderr)


def set_verbose(verbose: bool) -> None:
    global _verbose
    _verbose = verbose


def set_app(name: str) -> None:
    _current.app = name


def info(message: str) -> None:
    if _verbose:
        print(f"{_prefix()}{message}", file=sys.stderr)


def count(number: int, noun: str) -> str:
    """Return for example "1 screenshot" or "2 screenshots"."""
    return f"{number} {noun}" if number == 1 else f"{number} {noun}s"
