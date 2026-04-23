{
  config,
  pkgs,
  lib,
  ...
}:

{
  name = "qlever-ui";
  version = "0-unstable-2026-04-16";
  description = "User interface for QLever";
  homePage = "https://github.com/qlever-dev/qlever-ui";
  mainProgram = "qlever-ui";
  license = lib.licenses.asl20;

  source = {
    git = "github:qlever-dev/qlever-ui/b12823ffd25f0c9ebdc530ebd16868e7389ef0fa";
    hash = "sha256-aN4vj5zYy/rkfhEylHd5wYGxwEFaZCSnpZIIYhSQMeo=";
  };

  build.pythonAppBuilder = {
    enable = true;
    packages = {
      build-system = with pkgs.python3Packages; [
        setuptools
      ];
      dependencies = with pkgs.python3Packages; [
        django
        django-environ
        django-import-export
        djangorestframework
        gunicorn
        markdown
        pyyaml
        requests
        whitenoise
      ];
      run = with pkgs; [
        subversion
      ];
    };
    relaxDeps = [
      "django"
      "django-environ"
      "gunicorn"
      "requests"
      "whitenoise"
    ];
    importsCheck = [
      "qlever"
    ];
  };

  build.extraAttrs = {
    preBuild = ''
      cp -r ${pkgs.mypkgs.qlever-ui-frontend}/. ./backend/static/wasm/
    '';

    postInstall = ''
      makeWrapper ${pkgs.python3Packages.gunicorn}/bin/gunicorn \
        $out/bin/qlever-ui \
        --add-flags "qlever.wsgi:application" \
        --add-flags "--limit-request-line 10000" \
        --prefix PYTHONPATH : "$PYTHONPATH"

      cp -r $PWD $out/opt

      makeWrapper ${placeholder "out"}/opt/manage.py \
        $out/bin/qlever-ui-manage \
        --set DJANGO_SETTINGS_MODULE qlever.settings \
        --prefix PYTHONPATH : "$PYTHONPATH"
    '';
  };

  test.script = ''
    python -c "import qlever; print(qlever.__name__)"
  '';
}
