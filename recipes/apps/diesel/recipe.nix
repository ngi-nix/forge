{
  pkgs,
  ...
}:
{
  apps.diesel = {
    displayName = "Diesel";
    description = "Safe, Extensible ORM and Query Builder for Rust.";
    usage = ''
      Note: Diesel is primarily a Rust library. You use it in your code by adding the [`diesel`](https://crates.io/crates/diesel) crate to your `Cargo.toml` dependencies.

      The `diesel` helper CLI tool is used alongside your project to manage your database schema, generate boilerplate, and run migrations. Diesel officially supports PostgreSQL, MySQL, and SQLite.

      Before running any CLI commands, ensure you are inside a Rust project directory (where your `Cargo.toml` is located).
      You also need to provide your database connection URL. You can do this by setting the `DATABASE_URL` environment variable, typically in a `.env` file.

      For example, for PostgreSQL:
      ```bash
      echo "DATABASE_URL=postgres://user:password@localhost/mydb" > .env
      ```

      Once your `.env` file is ready, you can set up a new project (which creates a `diesel.toml` file and a `migrations` directory):

      ```bash
      diesel setup
      ```

      Create a new migration (replace `create_users` with your migration name):

      ```bash
      diesel migration generate create_users
      ```

      After writing your SQL up and down scripts in the generated migration folder, apply the migrations to your database:

      ```bash
      diesel migration run
      ```

      If you need to revert and re-apply the latest migration to test it:

      ```bash
      diesel migration redo
      ```

      For more commands and options, you can run `diesel --help`.
    '';
    icon = ./icon.svg;

    links = {
      docs = "https://diesel.rs/guides";
      website = "https://diesel.rs";
      source = "https://github.com/diesel-rs/diesel";
    };

    ngi.grants = {
      Core = [ "Diesel" ];
    };

    programs = {
      packages = [ pkgs.diesel-cli ];
      runtimes.shell.enable = true;
    };

    test.programs.script = ''
      set -x
      echo "DATABASE_URL=sqlite://my.db" > .env
      touch Cargo.toml
      diesel setup
      diesel migration generate create_users
      diesel migration run
      diesel migration redo
      set +x
    '';
  };
}
