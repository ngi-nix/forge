"""Named regex patterns for recipe field extraction and replacement."""

import re


def _string_field(name: str) -> re.Pattern[str]:
    """Match a double-quoted attribute (e.g. `cargoHash = "sha256-"`)."""
    return re.compile(rf'\b{re.escape(name)}\s*=\s*"([^"]*)"')


FIELD_VERSION = _string_field("version")
FIELD_GIT = _string_field("git")
FIELD_URL = _string_field("url")
FIELD_HASH = _string_field("hash")

FIELD_CARGO_HASH = _string_field("cargoHash")
FIELD_VENDOR_HASH = _string_field("vendorHash")
FIELD_NPM_DEPS_HASH = _string_field("npmDepsHash")
FIELD_PNPM_DEPS_HASH = _string_field("pnpmDepsHash")

# Matches `path = ./path/to/file`
FIELD_PATH = re.compile(r"\bpath\s*=\s*(\./[\w./-]+)")

# Matches `pkgs.NAME = {`
PACKAGE_BLOCK = re.compile(r"pkgs\.([\w-]+)\s*=\s*\{")

# Matches `builders.NAME = {`.
BUILDER_DECL = re.compile(r"\bbuilders\.(\w+)\s*=\s*\{")

# Self-referencing version values.
#
# `[^}]*` stops at the first closing brace, so only a single
# reference is matched. So, instead of matching the entirety of:
#
#   ${config.pkgs.foo.path}/v${recipe.version}
#
# We only match:
#
#   v${recipe.version}
#
PACKAGE_SELF_REFERENCE = re.compile(
    r"""
    \$\{
    [^}]*
    \.version
    \}
    """,
    re.VERBOSE,
)

# Matches `submodules = true`
SUBMODULES = re.compile(r"\bsubmodules\s*=\s*true")

# Matches `rev=abc123` or `tag=v1.2.3` in a generic git URL
GIT_REV = re.compile(r"\b(?:rev|tag)=([^&]+)")

# Matches the hash Nix returns after a fixed-output hash mismatch:
#   got:    sha256-...
NIX_BUILD_GOT_HASH = re.compile(r"got:\s+(sha256-\S+)")

# Matches the first numeric component in a tag (e.g. `v1.2.3` -> `1.2.3`)
NUMERIC_VERSION = re.compile(r"(\d+(?:\.\d+)*)")
