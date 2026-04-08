import json
import os
import sys
import random
import string
from pathlib import Path

sys.path.append("@devUIDir@")
from faker import Faker
from build_app_resources import populate_resources_dir

fake = Faker()

try:
    total_apps = int(sys.argv[1]) if len(sys.argv) > 1 else 5000
except ValueError:
    print("Error: Please provide a valid integer for the number of apps.")
    sys.exit(1)

out_file = sys.argv[2] if len(sys.argv) > 2 else "ui/build/forge-config.json"
out_file = Path(out_file)

os.makedirs(out_file.parents[0], exist_ok=True)

print(f"Generating {total_apps} apps...")


def generate_hash():
    chars = string.ascii_lowercase + string.digits
    return "".join(random.choices(chars, k=32))


def fake_store_path():
    return f"/nix/store/{generate_hash()}-{fake.word()}-1.0.0"


def generate_grants():
    # Initialize empty categories
    grants = {"Commons": [], "Core": [], "Entrust": [], "Review": []}
    categories = list(grants.keys())

    # Randomly distribute 1 to 5 grants across the categories
    for _ in range(random.randint(1, 5)):
        random_category = random.choice(categories)
        grants[random_category].append(fake.word())

    return grants


def generate_app(index: int):
    base_name = f"{fake.word()}-{fake.word()}".lower().replace("'", "")
    app_name = f"{base_name}-{index}-app"

    description = " ".join(fake.sentences(nb=random.randint(1, 3)))

    # Extracting variables keeps lines under the 79-character limit for flake8
    req_path = fake_store_path()
    cmd_path = fake_store_path()
    compose_file = f"/nix/store/{generate_hash()}-compose.yaml"
    greeting_env = f"GREETING={fake.sentence()}"

    container_enable = fake.boolean()
    nixos_enable = fake.boolean()

    return {
        "name": app_name,
        "description": description,
        "ngi": {
            "grants": generate_grants(),
        },
        "links": {
            "website": fake.word(),
            "docs": fake.word(),
            "source": fake.word(),
        },
        "programs": {"enable": True, "requirements": [req_path]},
        "services": {
            "components": {
                app_name: {
                    "argv": [],
                    "command": cmd_path,
                    "environment": [],
                    "result": {
                        "configData": {},
                        "process": {"argv": [f"{cmd_path}/bin/{app_name}"]},
                    },
                }
            },
            "runtimes": {
                "container": {
                    "composeFile": compose_file,
                    "enable": container_enable,
                    "imageConfig": {"Env": [greeting_env]},
                    "name": app_name,
                    "requirements": [req_path],
                    "result": "container",
                    "tag": "latest",
                },
                "nixos": {
                    "enable": nixos_enable,
                    "extraConfig": {},
                    "name": f"{app_name}-nixos",
                    "result": "nixos-vm-config",
                    "settings": {},
                    "vm": {
                        "cores": random.choice([2, 4, 8]),
                        "diskSize": random.choice([2048, 4096, 8192]),
                        "forwardPorts": [],
                        "memorySize": random.choice([1024, 2048, 4096]),
                    },
                },
            },
        },
        "usage": fake.text(),
    }


fake_data = {
    "apps": [generate_app(i) for i in range(total_apps)],
    "packages": [],
    "recipeDirs": {"apps": "recipes/apps", "packages": "recipes/packages"},
    "repositoryUrl": "github:ngi-nix/forge",
}

# remove if existing symlink by dev-ui exists
out_file.unlink(missing_ok=True)

with open(out_file, "w") as f:
    json.dump(fake_data, f)

print(f"Done! Wrote to {out_file}")


populate_resources_dir()
