{
  pkgs,
  config,
  lib,
  ...
}:
let
  recipe = config.pkgs.ties;
in
{
  pkgs.ties = {
    version = "0.3.0";
    description = "A federated network to bookmark, organize, share and discover good web pages.";
    homePage = "https://ties.pub";
    mainProgram = "ties";
    license = lib.licenses.agpl3Only;

    source = {
      git = "github:raffomania/ties/v${recipe.version}";
      hash = "sha256-42QqZeA3OfjAM86ysHXYgn2ZPJ7HNSjInW0+jHcEGmY=";
    };

    build.rustPackageBuilder = {
      enable = true;
      cargoHash = "sha256-4irWiRYyi51PbnAXly7aG2mXDnLstGR//UaZwMvpVas=";
      packages.check = [ pkgs.postgresql ];
    };

    build.extraAttrs = {
      checkType = "debug";
      preCheck = ''
        # spin up a temporary postgres server for testing
        export PGDATA="$TMPDIR/pgdata"
        export PGHOST="$TMPDIR/pgsocket"
        export DATABASE_URL="postgres://postgres@localhost/postgres?host=$PGHOST"

        mkdir -p "$PGDATA" "$PGHOST"
        initdb -D "$PGDATA" -U postgres --auth=trust --no-sync
        pg_ctl -D "$PGDATA" \
          -l "$TMPDIR/pg.log" \
          -o "-k $PGHOST" \
          -w start

        trap 'pg_ctl -D "$PGDATA" stop -m immediate || true' EXIT
      '';

      postCheck = ''
        pg_ctl -D "$PGDATA" stop -m immediate || true
      '';
    };

    test.script = ''
      ties --version | grep -q "${recipe.version}"
    '';
  };
}
