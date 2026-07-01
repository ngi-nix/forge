# Unfree packages

Some packages available in NGI Forge have licenses that are considered
"unfree" by Nixpkgs. This includes proprietary software or software with
licenses that restrict commercial use, redistribution, or modification.

By default, Nix will refuse to build or run packages with unfree licenses.
This guide explains how to configure Nix to allow them.

## Allow all unfree packages

The simplest approach is to allow all unfree packages globally by setting the
`allowUnfree` option in your Nix configuration.

:::{note}
This allows any unfree package to be built, not just those from NGI Forge.
:::

### With Flakes enabled

Add the following to your `NIX_CONFIG` environment variable, or set it before
running any `nix build` or `nix run` commands:

```bash
export NIX_CONFIG="allow-unfree = true"
```

To make this permanent, add it to your shell configuration file
(`~/.bashrc`, `~/.zshrc`, or similar).

### With traditional Nix

Add the following to `~/.config/nixpkgs/config.nix` or `/etc/nixos/configuration.nix`:

```nix
{
  allowUnfree = true;
}
```

## Allow only specific unfree packages

If you prefer to allow only certain unfree packages, use the
`allowUnfreePredicate` option instead. This gives you finer control.

```bash
export NIX_CONFIG="allow-unfree-predicate = (pkg: builtins.elem (lib.getName pkg) [ \"vscode\" \"steam\" ])"
```

Or in `configuration.nix`:

```nix
{
  allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "vscode" "steam" ];
}
```

## Verify the configuration

To check if your configuration is allowing unfree packages, run:

```bash
nix eval nixpkgs#config.allowUnfree
```

This should return `true` if unfree packages are allowed.

## Troubleshooting

### Error: "Package '<name>' has an unfree license"

If you see this error when trying to build or run a package:

```
error: Package 'vscode' has an unfree license 'vscode'.
       It is not allowed by default. Set 'nixpkgs.config.allowUnfree = true;'
```

It means unfree packages are not yet allowed. Follow the instructions above
to enable them.

### Error: "declarative flake configuration is not allowed"

If you see this error:

```
error: access to declarative flake configuration is not allowed.
       Set 'accept-flake-config = true' in Nix configuration.
```

Set the following environment variable:

```bash
export NIX_CONFIG="accept-flake-config = true"
```

This is required when using Forge's binary cache and is generally needed for
flakes that configure Nix options.
