#!/usr/bin/env python3

# Build resources directory for development mode

import os
import sys
import json
import shutil
import subprocess
from pathlib import Path
from typing import Any


def get_git_root() -> Path | None:
    try:
        print(os.getcwd())
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        )
        return Path(result.stdout.strip())

    except subprocess.CalledProcessError as e:
        print("Error: ", e.stderr)
        print("Error: The current directory is not part of a Git repository.")
        return None


def populate_resources_dir():
    try:
        root_dir = get_git_root()
        if not root_dir:
            print("Failed to find the project root directory using git.")
            exit(0)
        print(f"The Git root is: {root_dir}")

        build_dir = root_dir / "ui" / "build"
        resources_dir = build_dir / "resources"
        config_file = build_dir / "forge-config.json"

        apps_dir = resources_dir / "apps"
        apps_dir.mkdir(parents=True, exist_ok=True)

        default_icon_src = root_dir / "ui" / "src" / "app-icon.svg"
        default_icon_dest = apps_dir / "app-icon.svg"

        # Copy default icon to the base apps directory
        if default_icon_src.is_file():
            shutil.copy2(default_icon_src, default_icon_dest)

        # Check if config file exists
        if not config_file.is_file():
            print(
                "[build-app-resources] forge-config.json not found, only default icon copied"
            )
            return

        try:
            with open(config_file, "r", encoding="utf-8") as f:
                config: dict[str, str | list[Any] | Any] = json.load(f)
        except json.JSONDecodeError:
            print(f"[build-app-resources] Error parsing JSON in {config_file}")
            return

        app_count = 0
        apps: list[dict[str, str]] = config.get("apps", [])

        for app in apps:
            app_name: str = app.get("name", "")
            if not app_name:
                continue

            app_dir: Path = apps_dir / app_name
            app_dir.mkdir(parents=True, exist_ok=True)

            app_icon: str = app.get("icon")
            dest_icon: Path = app_dir / "icon.svg"
            icon_copied = False

            if app_icon:
                icon_file = Path(app_icon)
                _ = shutil.copy2(icon_file, dest_icon)
                icon_copied = True

            # Fallback to default icon if specific icon wasn't found or provided
            if not icon_copied and default_icon_src.is_file():
                _ = shutil.copy2(default_icon_src, dest_icon)

            app_count += 1

        print(
            f"[build-app-resources] Created {app_count} app icon(s) in {resources_dir}"
        )

    except Exception as e:
        # print the error and line number, but exit successfully (0)
        _, _, exc_tb = sys.exc_info()
        if exc_tb is not None:
            line_no = exc_tb.tb_lineno
            print(f"Error in build-app-resources.py at line {line_no}: {e}")


if __name__ == "__main__":
    populate_resources_dir()
