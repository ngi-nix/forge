"""Named regex patterns for recipe field extraction and replacement."""

FIELD_VERSION = r'version\s*=\s*"([^"]*)"'
FIELD_GIT = r'\bgit\s*=\s*"([^"]*)"'
FIELD_URL = r'\burl\s*=\s*"([^"]*)"'
FIELD_PATH = r"\bpath\s*=\s*(\./[\w./-]+)"
FIELD_HASH = r'\bhash\s*=\s*"([^"]*)"'
FIELD_CARGO_HASH = r'cargoHash\s*=\s*"([^"]*)"'
FIELD_VENDOR_HASH = r'vendorHash\s*=\s*"([^"]*)"'
FIELD_NPM_DEPS_HASH = r'npmDepsHash\s*=\s*"([^"]*)"'
FIELD_PNPM_DEPS_HASH = r'pnpmDepsHash\s*=\s*"([^"]*)"'

PACKAGE_BLOCK = r"pkgs\.([\w-]+)\s*=\s*\{"
PACKAGE_SELF_REFERENCE = r"\$\{config\.pkgs\..*\.version\}"
BUILDER_DECL = r"(\w+)Builder\s*=\s*\{"

SUBMODULES = r"submodules\s*=\s*true"
GIT_REV = r"(?:rev|tag)=([^&]+)"

NIX_BUILD_GOT_HASH = r"got:\s+(sha256-\S+)"

NUMERIC_VERSION = r"(\d+(?:\.\d+)*)"
