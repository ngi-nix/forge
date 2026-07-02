{
  lib,
  ...
}:

{
  pkgs.himalaya = {
    version = "1.2.0";
    description = "Command-line email client supporting IMAP, Maildir, and SMTP.";
    homePage = "https://pimalaya.org";
    mainProgram = "himalaya";
    license = lib.licenses.mit;

    source = {
      git = "github:pimalaya/himalaya/v1.2.0";
      hash = "sha256-BBzfDeNu7s010ARCYuydCyR7QWrbeI3/B4CxA6d4olw=";
    };

    build.rustPackageBuilder = {
      enable = true;
      cargoHash = "sha256-IkvRiU9NuD6n7aCF8J235u2LjjmLftnF1n874IWVcN0=";
    };

    test.script = ''
      himalaya --version
      himalaya --help
    '';
  };
}
