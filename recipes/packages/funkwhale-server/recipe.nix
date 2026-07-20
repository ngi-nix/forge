{
  config,
  lib,
  pkgs,
  ...
}:

{
  packages.funkwhale-server = {
    version = "2.0.2";
    description = "Federated platform for audio streaming, exploration, and publishing.";
    homePage = "https://www.funkwhale.audio/";
    mainProgram = "funkwhale-manage";
    license = lib.licenses.agpl3Only;

    source = {
      url = "https://dev.funkwhale.audio/funkwhale/funkwhale/-/archive/2.0.2/funkwhale-2.0.2.tar.gz";
      hash = "sha256-8Oii3JR/c5GvvYwgZZfc8DEPdlZH2cWV2NcHu0usy40=";
      patches = [
        ./replace-unicode-slugify.patch
        ./fix-root-filesystem-tests.patch
      ];
    };

    build.pythonAppBuilder = {
      enable = true;
      packages = {
        build-system = [
          pkgs.python3Packages.poetry-core
        ];
        dependencies =
          with pkgs.python3Packages;
          [
            dj-rest-auth
            django
            django-allauth
            django-cache-memoize
            django-cacheops
            django-cleanup
            django-cors-headers
            django-debug-toolbar
            django-dynamic-preferences
            django-environ
            django-filter
            django-oauth-toolkit
            django-redis
            django-storages
            django-versatileimagefield
            djangorestframework
            drf-spectacular
            markdown
            persisting-theory
            psycopg2-binary
            redis
            django-auth-ldap
            python-ldap
            channels
            channels-redis
            kombu
            celery
            uvicorn
            aiohttp
            arrow
            bleach
            boto3
            click
            cryptography
            defusedxml
            feedparser
            httpx
            python-ffmpeg
            liblistenbrainz
            musicbrainzngs
            mutagen
            pillow
            pyld
            python-magic
            requests
            requests-http-message-signatures
            sentry-sdk
            watchdog
            troi
            lb-matching-tools
            unidecode
            pycountry
            ipython
            pluralizer
            service-identity
            python-slugify
            pkgs.typesense-python
          ]
          ++ channels.optional-dependencies.daphne
          ++ uvicorn.optional-dependencies.standard;
      };
      relaxDeps = true;
    };

    build.extraAttrs = {
      postInstall = ''
        mkdir -p $out/bin

        cat > $out/bin/celery <<EOF
        #!/usr/bin/env python
        import sys
        from celery.__main__ import main
        sys.exit(main())
        EOF
        chmod +x $out/bin/celery

        cat > $out/bin/uvicorn <<EOF
        #!/usr/bin/env python
        import sys
        from uvicorn.main import main
        sys.exit(main())
        EOF
        chmod +x $out/bin/uvicorn
      '';

      sourceRoot = "funkwhale-2.0.2/api";

      pythonRemoveDeps = [
        "gunicorn"
      ];

      nativeCheckInputs = with pkgs.python3Packages; [
        pkgs.postgresql
        pkgs.postgresqlTestHook
        pkgs.redisTestHook
        pyfakefs
        aioresponses
        factory-boy
        faker
        ipdb
        pytest
        pytest-asyncio
        prompt-toolkit
        pytest-django
        pytest-env
        pytest-mock
        pytest-randomly
        pytest-sugar
        requests-mock
        django-extensions
      ];

      postgresqlTestUserOptions = "LOGIN SUPERUSER";
      checkPhase = ''
        runHook preCheck

        DATABASE_URL="postgresql:///$PGDATABASE?host=$PGHOST&user=$PGUSER" \
        FUNKWHALE_URL="https://example.com" \
        DJANGO_SETTINGS_MODULE="config.settings.local" \
        CACHE_URL="redis://$REDIS_SOCKET:6379/0" \
        python -m django migrate --no-input

        runHook postCheck
      '';
    };
  };

}
