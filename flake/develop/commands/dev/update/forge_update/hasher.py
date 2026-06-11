import json
import subprocess

from .errors import PrefetchError


class HashPrefetcher:
    prefetch_timeout: int

    def __init__(self, timeout: int = 180) -> None:
        self.prefetch_timeout = timeout

    def prefetch_git(self, remote_url: str, rev: str, submodules: bool = False) -> str:
        cmd = ["nix-prefetch-git", remote_url, "--rev", rev]
        if submodules:
            cmd.append("--fetch-submodules")

        stdout, stderr, returncode = self._run(cmd)
        if returncode != 0:
            raise PrefetchError(
                f"nix-prefetch-git failed (exit {returncode}): {stderr}"
            )

        try:
            data = json.loads(stdout)
        except json.JSONDecodeError as e:
            raise PrefetchError(f"failed to parse nix-prefetch-git output: {e}")

        hash_val = data.get("hash")
        if not hash_val:
            raise PrefetchError("nix-prefetch-git output missing 'hash' field")
        return hash_val

    def _run(self, cmd: list[str]) -> tuple[str, str, int]:
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=self.prefetch_timeout,
            )
            return result.stdout, result.stderr, result.returncode
        except subprocess.TimeoutExpired:
            cmd_str = " ".join(cmd[:2]) + "..."
            raise PrefetchError(f"{cmd_str} timed out ({self.prefetch_timeout}s)")
        except FileNotFoundError as e:
            raise PrefetchError(f"{e.filename} not found")
