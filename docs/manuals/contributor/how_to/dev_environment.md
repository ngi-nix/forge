# How to use a built-in package development environment

::: {important}
For the list of all available configuration options for development environment configuration,
see the
[packages develop options reference](https://ngi.nixos.org/recipe/options?s=pkgs.%3Cname%3E.develop).
:::

NGI Forge provides a built-in development environment containing all
dependencies required to build a package from source by running a single
`nix develop .#pkgs.<package-name>.env` command.

## Development environment

Launch a development environment for the `hello-web` package:

```bash
nix develop .#pkgs.hello-web.env

# or
nix-shell -A pkgs.hello-web.env default.nix
```

```bash
Welcome. This environment contains all dependencies required
to build hello-web from source.

Grab the source code from /nix/store/89d286yd9nj83pz0g8rq56ia6p7l588y-src
or from the upstream repository and you are all set to start hacking.
```

Copy the source code from the Nix store path printed above to a writable
directory:

```bash
cp -r --no-preserve=mode,ownership \
  /nix/store/89d286yd9nj83pz0g8rq56ia6p7l588y-src \
  src/
cd src
```

Build the package:

```bash
go build -o hello-web .
```

Run the binary:

```bash
./hello-web
Hello, world!
```

## Environment customization

Additional environment packages and a entry script can be configured.

For example, add the following configuration to
`recipes/pkgs/hello-web/recipe.nix` to add the Go language linter and
customize a default welcome message:

```nix
pkgs.hello-web = {
  ...
  develop = {
    packages = with pkgs; [ golangci-lint ];
    shellHook = ''
      echo
      echo "Build the $ENV_PACKAGE_NAME from source:"
      echo
      echo "  cp -r --no-preserve=mode,ownership $ENV_PACKAGE_SOURCE src/"
      echo "  cd src"
      echo
      echo "  go build -o hello-web ."
      echo
      echo "Run the linter:"
      echo
      echo "  golangci-lint run ."
    '';
  };
};
```

Re-launch the development environment:

```bash
nix develop .#pkgs.hello-web.env

Build hello-web from source:

  cp -r --no-preserve=mode,ownership /nix/store/89d286yd9nj83pz0g8rq56ia6p7l588y-src src/
  cd src

  go build -o hello-web .

Run the linter:

  golangci-lint run .
```

Run the linter:

```bash
golangci-lint run .

main.go:22:13: Error return value of `fmt.Fprint` is not checked (errcheck)
		fmt.Fprint(w, message)
		          ^
1 issues:
* errcheck: 1
```
