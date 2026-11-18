import sys
import threading

_verbose = False
# The application that the current thread updates or checks, for `info`.
_current = threading.local()


def warn(message: str) -> None:
    print(f"warning: {message}", file=sys.stderr)


def set_verbose(verbose: bool) -> None:
    global _verbose
    _verbose = verbose


def set_app(name: str) -> None:
    _current.app = name


def info(message: str) -> None:
    if _verbose:
        print(f"{getattr(_current, 'app', '')}: {message}", file=sys.stderr)
