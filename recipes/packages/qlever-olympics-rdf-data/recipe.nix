{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "qlever-olympics-rdf-data";
  version = "0-master-2023-01-01";
  description = "Olympics RDF dataset for use with QLever SPARQL engine.";
  homePage = "https://github.com/wallscope/olympics-rdf";
  license = lib.licenses.mit;

  source = {
    url = "https://github.com/wallscope/olympics-rdf/raw/54483d539082641d48e1d49873662b3af628ca4d/data/olympics-nt-nodup.zip";
    hash = "sha256-dY28CQKaMDUUw/pw+p9yX0EtJOnbAAplodMFaedL1B8=";
  };

  build.standardBuilder = {
    enable = true;
    packages.build = with pkgs; [
      unzip
    ];
  };

  build.extraAttrs = {
    dontBuild = true;
    dontUnpack = true;
    installPhase = ''
      unzip $src
      install -D olympics.nt -t $out
    '';
  };
}
