{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  perl,
  languages ? [
    "plaintext"
    "bash"
    "json"
    "nix"
    "python"
    "sql"
    "yaml"
    "markdown"
  ],
  # https://highlightjs.org/examples
  # https://highlightjs.org/demo
  theme ? "github-dark",
}:
buildNpmPackage (finalAttrs: {
  pname = "highlight.js";
  # TODO: updateScript
  version = "11.12.0";

  src = fetchFromGitHub {
    owner = "highlightjs";
    repo = "highlight.js";
    rev = finalAttrs.version;
    hash = "sha256-Vg3yHy/aU7GG3rePaMr4625PgwUkCkazxGxGxQ4Fw/Q=";
  };

  npmDepsHash = "sha256-3PmhXZlBMJjNDxhqq1DR559mEwPqt/tkdD1JUtp3nUk=";

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
