{
  lib,
  ...
}:

{
  pkgs.himalaya = {
    version = "2.2.1";
    description = "Command-line email client supporting IMAP, Maildir, and SMTP.";
    homePage = "https://pimalaya.org";
    mainProgram = "himalaya";
    license = lib.licenses.mit;

    source = {
      git = "github:pimalaya/himalaya/v2.2.1";
      hash = "sha256-fYspChAGb0PLdsgP5GViAwp4NdmDXDyait0mpqIkGfQ=";
    };

    build.builders.rust = {
      enable = true;
      cargoHash = "sha256-KDsvF8wHMIEw+rjBJpUTgX6QIhcCMVjLWcPWklpxG3Q=";
    };

    test.script = ''
      himalaya --version
      himalaya --help
    '';
  };
}
