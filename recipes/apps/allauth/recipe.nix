{
  lib,
  pkgs,
  config,
  ...
}:
{
  apps.allauth = {
    displayName = "Django Allauth";
    description = "Django library for authentication, account management as well as 3rd party (social) account authentication.";
    usage = ''
      A free, secure, well integrated, reusable authentication solution for the Django framework, covering all functionality related to local and social user accounts, multi-factor authentication, in various configurations.

      To view the full capabilities of allauth, see [Demo projects](https://docs.allauth.org/en/latest/installation/examples.html) and the [Docs](${config.apps.allauth.links.docs}).

      This environment provides a python with the `django-allauth` python package with all its optional-dependencies installed.
    '';

    icon = ./icon.svg;

    ngi.grants = {
      Entrust = [ "django-allauth" ];
    };

    links = {
      website = "https://allauth.org";
      source = "https://codeberg.org/allauth/django-allauth";
      docs = "https://docs.allauth.org/en/latest/installation/quickstart.html";
    };

    programs = {
      packages = [
        (pkgs.python3.withPackages (
          ps: [ ps.django-allauth ] ++ (lib.concatAttrValues ps.django-allauth.optional-dependencies)
        ))
      ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      python -c '
      from allauth import VERSION
      semver = ".".join(map(str, VERSION[:3]))
      assert semver == "${pkgs.python3.pkgs.django-allauth.version}"
      '
    '';
  };
}
