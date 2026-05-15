{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  perl,
  languages ? [
    "shell"
    "bash"
  ],
  theme ? "github-dark",
}:
buildNpmPackage (finalAttrs: {
  pname = "highlight.js";
  version = "11.11.1";

  src = fetchFromGitHub {
    owner = "highlightjs";
    repo = "highlight.js";
    rev = finalAttrs.version;
    hash = "sha256-f+yC6SHkFKoY2ecP5EUENzewq+4PFC3Yy+8VRKY/+NY=";
  };

  npmDepsHash = "sha256-hMci5DCdcxh9RoPB2HUAsSa25FffyatZ4NXeoutIjHI=";

  # Remove impurity: highlight.js build script tries to run git to get the version hash.
  postPatch = ''
    ${perl}/bin/perl -0777 -i -pe 's/git_sha: child_process\s*\.execSync\("git rev-parse --short=10 HEAD"\)\s*\.toString\(\)\.trim\(\)/git_sha: "built-with-nix"/g' tools/build_browser.js
  '';

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    node tools/build.js \
      --target browser \
      ${lib.concatStringsSep " " languages}

    mkdir -p $out
    cp -v build/highlight.min.js $out/

    THEME_PATH="build/demo/styles/${theme}.css"
    if [ ! -f "$THEME_PATH" ]; then
      # Check base16 subfolder
      THEME_PATH="build/demo/styles/base16/${theme}.css"
    fi

    if [ -f "$THEME_PATH" ]; then
      cp -v "$THEME_PATH" $out/theme.css
    else
      echo "Error: Theme '${theme}' not found in build/demo/styles/ or build/demo/styles/base16/"
      exit 1
    fi

    runHook postInstall
  '';

  meta = {
    description = "Minified highlight.js bundle with pre-selected languages";
    homepage = "https://highlightjs.org/";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
  };
})
