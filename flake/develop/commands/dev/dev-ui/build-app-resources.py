#!/usr/bin/env python3

# Build resources directory for development mode

import sys
import json
import shutil
from pathlib import Path
from types import TracebackType
from typing import Any


def main():
    try:
        # Get root directory relative to this script location
        # This script is at: flake/develop/commands/dev/dev-ui/build-app-resources.py
        script_path = Path(__file__).resolve()

        # .parents[5] goes up 5 directories, equivalent to ../../../../..
        root_dir = script_path.parents[5]

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

            # Remove '-app' suffix for directory name
            app_dir_name = app_name[:-4] if app_name.endswith("-app") else app_name
            app_dir: Path = apps_dir / app_dir_name
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
    main()
