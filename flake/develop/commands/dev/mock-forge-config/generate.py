import json
import os
import sys
import random
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

    return {
        "name": app_name,
        "description": description,
        "ngi": {
            "grants": generate_grants(),
        },
        "links": {
            "website": {
                "url": fake.url(),
            },
            "docs": {
                "url": fake.url(),
            },
            "source": {
                "url": fake.url(),
            },
        },
        "programs": {
            "runtimes": {
                "shell": {
                    "enable": fake.boolean(),
                },
            },
        },
        "services": {
            "components": {
                app_name: {},
            },
            "runtimes": {
                "container": {
                    "enable": fake.boolean(),
                },
                "nixos": {
                    "enable": fake.boolean(),
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
