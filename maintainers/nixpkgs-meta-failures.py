#!/usr/bin/env -S nix run nixpkgs#python3 --
"""Generate a JSON list of package link failures for nixpkgs meta links.

By default, this script automatically:
  1. Generates pkgs.csv using maintainers/nixpkgs-meta.nix
  2. Runs lychee link checker (--format json)
  3. Maps failing URLs to package names and outputs structured JSON

USAGE:
  # Automatically generate pkgs.csv, check links, and emit JSON report:
  ./maintainers/nixpkgs-meta-failures.py | tee failures.json

  # Or use pre-generated pkgs.csv and lychee.json:
  ./maintainers/nixpkgs-meta-failures.py pkgs.csv lychee.json | tee failures.json
"""

import argparse
import json
import os
import subprocess
import sys
import tempfile


def parse_csv(csv_path: str) -> dict[int, dict[str, str]]:
    """Parse pkgs.csv into a mapping from 1-indexed line numbers to package metadata."""
    pkgs = {}
    with open(csv_path, "r", encoding="utf-8") as f:
        for idx, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            parts = line.split(",", 3)
            if len(parts) == 4:
                pkgs[idx] = {
                    "package": parts[0].strip(),
                    "attribute": parts[1].strip(),
                    "file": parts[2].strip(),
                }
            else:
                pkgs[idx] = {
                    "package": parts[0].strip(),
                    "attribute": "",
                    "file": "",
                }
    return pkgs


def parse_lychee_json(
    content: str, pkgs: dict[int, dict[str, str]]
) -> list[dict[str, dict[str, str]]]:
    """Parse Lychee JSON output (--format json) and map errors and redirects to package names."""
    data = json.loads(content)
    results = []

    def process_item(err: dict, is_success: bool) -> None:
        span = err.get("span", {})
        line_num = span.get("line")
        if not line_num or line_num not in pkgs:
            return

        info = pkgs[line_num]
        url = err.get("url", "")
        status = err.get("status", "")
        code = ""
        if isinstance(status, dict):
            code = str(status.get("code", ""))
            failure_text = status.get("text") or status.get("details") or str(status)
        else:
            failure_text = str(status)

        new_url = ""
        redirs = err.get("redirects")
        if redirs and isinstance(redirs, dict):
            redir_list = redirs.get("redirects", [])
            if redir_list and isinstance(redir_list, list):
                last = redir_list[-1]
                first = redir_list[0]
                if isinstance(last, dict):
                    new_url = str(last.get("url", ""))
                if isinstance(first, dict) and "code" in first:
                    if is_success or not code:
                        code = str(first["code"])

        # If it's a success_map item but has no redirects, skip it
        if is_success and not new_url:
            return

        if is_success and new_url:
            failure_text = f"Redirected ({code}) to {new_url}"

        val = {
            "attribute": info.get("attribute", ""),
            "file": info.get("file", ""),
            "url": url,
            "redirect": new_url,
            "code": code,
            "status": failure_text,
        }
        results.append({info["package"]: val})

    error_map = data.get("error_map", {})
    for errors in error_map.values():
        for err in errors:
            process_item(err, is_success=False)

    success_map = data.get("success_map", {})
    for successes in success_map.values():
        for err in successes:
            process_item(err, is_success=True)

    return results


def run_checks() -> tuple[dict[int, dict[str, str]], str]:
    """Automatically generate pkgs.csv and run lychee link checker."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    repo_root = os.path.dirname(script_dir)
    nix_file = os.path.join(script_dir, "nixpkgs-meta.nix")

    with tempfile.TemporaryDirectory() as tmpdir:
        csv_path = os.path.join(tmpdir, "pkgs.csv")

        print(
            "Generating pkgs.csv from maintainers/nixpkgs-meta.nix...",
            file=sys.stderr,
        )
        cmd_csv = [
            "nix",
            "eval",
            "--raw",
            "--extra-experimental-features",
            "pipe-operators",
            "-f",
            nix_file,
            "metaCSV",
        ]
        with open(csv_path, "w", encoding="utf-8") as f_out:
            res_csv = subprocess.run(cmd_csv, stdout=f_out, cwd=repo_root, check=False)
            if res_csv.returncode != 0:
                print(
                    f"error: nix eval failed with exit code {res_csv.returncode}",
                    file=sys.stderr,
                )
                sys.exit(res_csv.returncode)

        pkgs = parse_csv(csv_path)

        print("Running lychee link checker...", file=sys.stderr)
        cmd_lychee = [
            "nix",
            "run",
            ".#apps.lychee",
            "--",
            "-v",
            csv_path,
            "-m",
            "5",
            "-f",
            "json",
        ]
        res_lychee = subprocess.run(
            cmd_lychee,
            stdout=subprocess.PIPE,
            text=True,
            cwd=repo_root,
            check=False,
        )
        # Lychee returns 0 if all links succeed, 2 if there are link errors
        if res_lychee.returncode not in (0, 2):
            print(
                f"error: lychee failed with exit code {res_lychee.returncode}",
                file=sys.stderr,
            )
            sys.exit(res_lychee.returncode)

        return pkgs, res_lychee.stdout


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate JSON list of attribute sets mapping package names to link failures."
    )
    parser.add_argument(
        "csv_path",
        nargs="?",
        default=None,
        help="Optional path to pkgs.csv (if omitted, automatically generated via nix eval)",
    )
    parser.add_argument(
        "json_path",
        nargs="?",
        default=None,
        help="Optional path to lychee JSON file (if omitted, automatically run via nix run .#apps.lychee)",
    )
    parser.add_argument(
        "-o",
        "--output",
        default=None,
        help="Optional path to write JSON output (default: stdout)",
    )

    args = parser.parse_args()

    if args.csv_path and args.json_path:
        if not os.path.exists(args.csv_path):
            print(f"error: CSV file not found: {args.csv_path}", file=sys.stderr)
            return 1
        if not os.path.exists(args.json_path):
            print(
                f"error: lychee JSON file not found: {args.json_path}",
                file=sys.stderr,
            )
            return 1
        pkgs = parse_csv(args.csv_path)
        with open(args.json_path, "r", encoding="utf-8") as f:
            content = f.read()
    elif args.csv_path or args.json_path:
        print(
            "error: must specify both csv_path and json_path, or omit both to run automatically",
            file=sys.stderr,
        )
        return 1
    else:
        pkgs, content = run_checks()

    results = parse_lychee_json(content, pkgs)

    # Sort deterministically by package name, attribute, then URL
    results.sort(
        key=lambda d: (
            list(d.keys())[0],
            list(d.values())[0].get("attribute", ""),
            list(d.values())[0].get("url", ""),
        )
    )

    formatted_json = json.dumps(results, indent=2, ensure_ascii=False)
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(formatted_json + "\n")
    else:
        print(formatted_json)

    return 0


if __name__ == "__main__":
    sys.exit(main())
