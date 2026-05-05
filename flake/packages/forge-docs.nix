{
  lib,
  python3,
  stdenv,
}:

let
  sphinxEnv = python3.withPackages (
    ps: with ps; [
      linkify-it-py
      sphinx
      myst-parser
      sphinx-book-theme
      sphinx-copybutton
      sphinx-design
      sphinx-sitemap
      sphinx-notfound-page
    ]
  );
in

stdenv.mkDerivation {
  pname = "_forge-docs";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ../../docs;
    fileset = lib.fileset.difference (lib.fileset.gitTracked ../../docs) (
      lib.fileset.maybeMissing ../../docs/build
    );
  };

  nativeBuildInputs = [ sphinxEnv ];

  buildPhase = ''
    sphinx-build -b html -W . $out
  '';

  dontInstall = true;

  meta = {
    description = "NGI Forge HTML documentation";
  };
}
