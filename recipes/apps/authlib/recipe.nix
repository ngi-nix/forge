{
  lib,
  pkgs,
  config,
  ...
}:
let
  recipe = config.apps.authlib;
in
{
  apps.authlib = {
    displayName = "Authlib";
    description = "The ultimate Python library in building OAuth and OpenID Connect servers. JWS, JWK, JWA, JWT are included.";
    categories = with lib.categories; [ Development ];
    usage = ''
      Authlib is a Python library for building OAuth 1.0, OAuth 2.0, and OpenID
      Connect clients and providers, including JWS, JWK, JWA, and JWT support.

      To view the full capabilities of Authlib, see the [Docs](${recipe.links.docs}).

      This environment provides a Python with the `authlib` package installed.
    '';

    links = {
      website = "https://authlib.org";
      source = "https://github.com/authlib/authlib";
      docs = "https://docs.authlib.org/";
    };

    ngi.grants = {
      Commons = [
        "Authlib"
      ];
    };

    icon = ./icon.svg;

    programs = {
      packages = [
        (pkgs.python3.withPackages (ps: [ ps.authlib ]))
      ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      python -c '
      import authlib
      assert authlib.__version__ == "${pkgs.python3.pkgs.authlib.version}"
      '
    '';
  };
}
