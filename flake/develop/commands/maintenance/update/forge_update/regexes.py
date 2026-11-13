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

# Matches a version at the end of a tag name, with an optional name prefix
# and/or `v`:
#
#   v2.1.1
#   1.10.0
#   sequoia-sq/v1.5.0
#   release_1.2.3-rc.1+build.5
#
# Does not match (no dotted version, or trailing junk after it):
#
#   node-redis_v18-7
#   v1.2.3.beta
#   1.2.3rc1
#
# Use with `.search()`. The version is captured in the `version` group,
# without the `v` prefix or any pre-release/build suffix.
VERSION_TAG = re.compile(
    r"""
    (?:^|[/_-])                      # start of tag, or a separator before the version
    v?                               # optional `v` prefix
    (?P<version>\d+\.\d+(?:\.\d+)*)  # dotted numeric version, at least MAJOR.MINOR
    (?:-[0-9A-Za-z.-]+)?             # optional pre-release, e.g. `-rc.1`
    (?:\+[0-9A-Za-z.-]+)?            # optional build metadata, e.g. `+build.5`
    \Z                               # end of string (`$` would also match before a trailing newline)
    """,
    re.VERBOSE,
)

# Matches pre-release markers in the suffix of a version, e.g.:
#
#   -rc.1  -beta  -alpha.1  -preview  -SNAPSHOT  -unstable  -m1
#
# Does not match:
#
#   -1      (numeric packaging revision)
#   -esp32  (vendor suffix)
PRERELEASE = re.compile(
    r"""
    (?:^|[-._])
    (?:alpha|beta|canary|nightly|prerelease|preview|snapshot|unstable|dev|rc|pre|m\d+)
    (?![a-z])  # not the start of a longer word, e.g. "-prefix"
    """,
    re.IGNORECASE | re.VERBOSE,
)
