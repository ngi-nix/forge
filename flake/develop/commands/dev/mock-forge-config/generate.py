import sys
import subprocess
import shutil
import tempfile
from pathlib import Path
from faker import Faker

fake = Faker()


def run_command(cmd, **kwargs):
    print(f"\n+ {' '.join(map(str, cmd))}")
    return subprocess.run(cmd, **kwargs)


def generate_grants():
    grants = {"Commons": [], "Core": [], "Entrust": [], "Review": []}
    for _ in range(fake.random_int(min=1, max=3)):
        grants[fake.random_element(elements=list(grants.keys()))].append(fake.word())
    return grants


def generate_package_recipe(name, index):
    return f"""{{
  config,
  lib,
  pkgs,
  ...
}}:

{{
  name = "{name}";
  version = "0.0.{index}";
  description = "{fake.sentence()}";
  homePage = "{fake.url()}";
  mainProgram = "{name}";
  license = lib.licenses.mit;

  source.url = "https://example.com/{name}.tar.gz";
  source.hash = lib.fakeHash;

  build.standardBuilder.enable = true;
}}
"""


def generate_app_recipe(name, index, is_test_app=False):
    grants = generate_grants()

    grant_lines = []
    for cat, items in grants.items():
        if items:
            vals = " ".join(f'"{v}"' for v in items)
            grant_lines.append(f"    {cat} = [ {vals} ];")

    grants_nix = "{\n" + "\n".join(grant_lines) + "\n  }"

    # Force enable all runtimes for the test app
    shell_en = "true" if is_test_app else str(fake.boolean()).lower()
    container_en = "true" if is_test_app else str(fake.boolean()).lower()
    nixos_vm_en = "true" if is_test_app else str(fake.boolean()).lower()

    return f"""{{
  config,
  lib,
  pkgs,
  ...
}}:

{{
  name = "{name}";
  description = "{fake.sentence()}";
  usage = "{fake.text()}";

  links = {{
    website = "{fake.url()}";
    docs = "{fake.url()}";
    source = "{fake.url()}";
  }};

  ngi.grants = {grants_nix};

  services = {{
    components.{name} = {{
      command = pkgs.hello;
    }};
    runtimes = {{
      container = {{
        enable = {container_en};
        packages = [ pkgs.hello ];
      }};
      nixos = {{
        enable = {nixos_vm_en};
        extraConfig = {{ }};
      }};
    }};
  }};

  programs = {{
    packages = [ pkgs.hello ];
    runtimes.shell.enable = {shell_en};
  }};
}}
"""


def main():
    try:
        num_apps = int(sys.argv[1]) if len(sys.argv) > 1 else 20
        num_packages = int(sys.argv[2]) if len(sys.argv) > 2 else 20
        out_path = Path(
            sys.argv[3] if len(sys.argv) > 3 else "ui/build/forge-config.json"
        )
    except (ValueError, IndexError):
        print("Usage: mock-forge-config <num_apps> <num_packages> <out_path>")
        sys.exit(1)

    git_root = Path(
        run_command(
            ["git", "rev-parse", "--show-toplevel"],
            stdout=subprocess.PIPE,
            text=True,
            check=True,
        ).stdout.strip()
    )
    if not out_path.is_absolute():
        out_path = git_root / out_path

    print(f"Generating {num_apps} apps and {num_packages} package recipes...")

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)
        run_command(
            [
                "git",
                "archive",
                "--format=tar",
                "HEAD",
                "-o",
                str(temp_path / "repo.tar"),
            ],
            cwd=str(git_root),
            check=True,
        )
        run_command(["tar", "-xf", "repo.tar"], cwd=str(temp_path), check=True)

        mock_recipes_root = temp_path / "recipes"
        if mock_recipes_root.exists():
            shutil.rmtree(mock_recipes_root)

        apps_dir, pkgs_dir = mock_recipes_root / "apps", mock_recipes_root / "packages"
        apps_dir.mkdir(parents=True), pkgs_dir.mkdir(parents=True)

        # Generate an unchanging test app
        test_app_name = "mock-test-app"
        (apps_dir / test_app_name).mkdir(parents=True)
        with open(apps_dir / test_app_name / "recipe.nix", "w") as f:
            f.write(generate_app_recipe(test_app_name, 0, is_test_app=True))

        for i in range(num_apps):
            app_name = f"mock-app-{i}"
            (apps_dir / app_name).mkdir(parents=True)
            with open(apps_dir / app_name / "recipe.nix", "w") as f:
                f.write(generate_app_recipe(app_name, i))

        # Generate a unchanging test package
        test_pkg_name = "mock-test-package"
        (pkgs_dir / test_pkg_name).mkdir(parents=True)
        with open(pkgs_dir / test_pkg_name / "recipe.nix", "w") as f:
            f.write(generate_package_recipe(test_pkg_name, 0))

        for i in range(num_packages):
            pkg_name = f"mock-package-{i}"
            (pkgs_dir / pkg_name).mkdir(parents=True)
            with open(pkgs_dir / pkg_name / "recipe.nix", "w") as f:
                f.write(generate_package_recipe(pkg_name, i))

        run_command(["git", "init"], cwd=str(temp_path), check=True)
        run_command(
            ["git", "config", "user.email", "foo@example.com"],
            cwd=str(temp_path),
            check=True,
        )
        run_command(
            ["git", "config", "user.name", "foo"],
            cwd=str(temp_path),
            check=True,
        )
        run_command(["git", "add", "."], cwd=str(temp_path), check=True)
        run_command(
            ["git", "commit", "-m", "gen mock recipes"],
            cwd=str(temp_path),
            check=True,
        )

        try:
            result = run_command(
                ["nix", "eval", ".#_forge-config.text", "--raw"],
                cwd=str(temp_path),
                stdout=subprocess.PIPE,
                text=True,
                check=True,
            )
            config_text = result.stdout
        except subprocess.CalledProcessError:
            print("Nix evaluation failed in temp repo")
            sys.exit(1)

    tmp_dir = git_root / "ui/build/.tmp"
    tmp_dir.mkdir(parents=True, exist_ok=True)
    real_file = tmp_dir / "mock-forge-config.json"
    with open(real_file, "w") as f:
        f.write(config_text)

    if out_path.exists() or out_path.is_symlink():
        out_path.unlink()

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.symlink_to(real_file.relative_to(out_path.parent))
    print(f"Mock config symlinked: {out_path} -> {real_file}")

    sys.path.append("@devUIDir@")
    try:
        from build_app_resources import populate_resources_dir

        populate_resources_dir()
    except ImportError:
        pass


if __name__ == "__main__":
    main()
