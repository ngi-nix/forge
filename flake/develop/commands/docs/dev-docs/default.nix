# Usage:
#   nix-shell --run 'dev-docs'
{
  gitMinimal,
  writeShellApplication,

  defaultListenPort ? 3001,
}:

writeShellApplication {
  name = "dev-docs";
  runtimeInputs = [ gitMinimal ];
  # Note: `sphinx-autobuild` is provided by the Python environment of the dev
  # shell, together with the Sphinx extensions used by the documentation.
  text = ''
    docsDir="$(git rev-parse --show-toplevel)/docs"

    exec sphinx-autobuild \
      -W \
      -d "$docsDir/build/doctrees" \
      --host "''${DOCS_HOST:-127.0.0.1}" \
      --port "''${listenPort:-${toString defaultListenPort}}" \
      "$docsDir" \
      "$docsDir/build/html" \
      "$@"
  '';
  meta.description = "launch documentation development server";
}
