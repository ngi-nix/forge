{
  lib,
  pkgs,
  ...
}:

{
  pkgs.neverest = {
    version = "0.3.0";
    description = "CLI to synchronize PIM collections: mail, contact, calendar.";
    homePage = "https://pimalaya.org";
    mainProgram = "neverest";
    license = lib.licenses.mit;

    source = {
      git = "github:pimalaya/neverest/v0.3.0";
      hash = "sha256-nZ0qW1AIjKpmLQdXVDSHm9yedga451EF9yz3djWflJY=";
    };

    build.builders.rust = {
      enable = true;
      cargoHash = "sha256-Pn7wK8+tR8qfyOR0W/RZUm+6IxlN4QjiQB5QXLXt55I=";
      packages.run = with pkgs; [
        libgit2
        sqlite
        openssl
      ];
      packages.build = with pkgs; [
        pkg-config
        installShellFiles
      ];
    };

    build.extraAttrs = {
      cargoTestFlags = [
        "--bins"
      ];
    };

    build.phases.install.script.post = ''
      mkdir -p "$out"/share/{completions,man}
      "$out"/bin/neverest manual -d "$out"/share/man
      "$out"/bin/neverest completion -d "$out"/share/completions bash elvish fish powershell zsh
      installManPage "$out"/share/man/*
      installShellCompletion --cmd neverest \
        --bash "$out"/share/completions/neverest.bash \
        --fish "$out"/share/completions/neverest.fish \
        --zsh "$out"/share/completions/_neverest
    '';

    test.script = ''
      neverest --version
      neverest --help
    '';
  };
}
