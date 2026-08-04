# How to update a package recipe

The Forge provides a script for updating package recipes to the latest upstream versions.

To access it, start by entering the development environment:

```bash
nix develop

# or
nix-shell
```

Then, to see all available options run:

```bash
forge-update --help
```

::: {note}
Update script can also be launched without entering the development environment:

```bash
nix develop --command forge-update

# or
nix-shell --run "forge-update
```

:::

## Usage Examples

Update individual recipes:

```bash
forge-update tau-tower
```

Update multiple recipes:

```bash
forge-update tau-tower tau-radio
```

Update all recipes:

```bash
forge-update --all
```

Update recipes and commit changes:

```bash
forge-update tau-radio --commit
```

Update recipes, but don't prefetch hashes or modify recipe files:

```bash
forge-update tau-radio --dry-run
```
