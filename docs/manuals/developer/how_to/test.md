# How to test

## How to test the UI

There are two commands available to run the elm UI in the project devshell.

- `forge-ui` serves the production UI locally.
- `dev-ui` serves a UI with generated apps meant to be used for testing purposes
  and for faster iteration on UI changes.

### Basic test

Run basic tests using [Playwright](https://playwright.dev/):

```bash
dev-ui

test-ui --project=chromium
```

::: {note} `test-ui` is a shell wrapper around `playwright test -c ui/tests/e2e`
without any extra arguments forwarded to that command.

:::

### Advanced test configuration

- Run tests only using specific browser

```bash
test-ui --project=chromium
test-ui --project=firefox --project=mobile
```

- Run tests with a single worker

```bash
test-ui -j 1
```

- Open the playwright web UI to iterate on the tests

```bash
test-ui --ui
test-ui --ui-host 127.0.0.1
```

- Run the tests using Forge production instance

```bash
env BASE_URL="https://ngi-nix.github.io/forge/" test-ui --ui-host 127.0.0.1
```

### Notes

- Always use `data-testid` HTML attributes for stable test selectors.
