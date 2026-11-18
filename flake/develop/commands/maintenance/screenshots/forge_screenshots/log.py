import sys
import threading

VERBOSE = False
# The application that the current thread updates or checks, for `info`.
_current = threading.local()


def warn(message: str) -> None:
    print(f"warning: {message}", file=sys.stderr)


def set_app(name: str) -> None:
    _current.app = name


def info(message: str) -> None:
    if VERBOSE:
        print(f"{getattr(_current, 'app', '')}: {message}", file=sys.stderr)
