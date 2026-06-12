{
  pkgs,
  ...
}:

{
  apps.oku = {
    displayName = "Oku";
    description = "Browser and encrypted data vault based on IPFS.";
    usage = ''
      Oku is a web browser built on top of IPFS that provides an encrypted personal
      data vault and supports peer-to-peer websites.
    '';

    links = {
      source = "https://github.com/okubrowser/oku";
    };

    ngi.grants = {
      Entrust = [
        "Oku"
      ];
    };

    programs = {
      mainPackage = pkgs.oku;
      runtimes.program.enable = true;
    };
  };
}
