# How to test

## How to test the UI

Run tests using [Playwright](https://playwright.dev/):

```bash
dev-ui-mock
test-ui --project=chromium
```

`test-ui` is a shell wrapper around `playwright test -c ui/tests/e2e` with any extra arguments forwarded to that command.

The following are some useful commands when using playwright cli.

Run tests only on specific browser.

```bash
test-ui --project=chromium
test-ui --project=firefox --project=mobile
```

Playwright runs `$(nproc)/2` workers by default.

```bash
test-ui -j 1
```

Open the playwright web UI to iterate on the tests.

```bash
test-ui --ui
test-ui --ui-host 127.0.0.1
```

Run the tests on our production deployment.

```bash
env BASE_URL="https://ngi-nix.github.io/forge/" test-ui --ui-host 127.0.0.1
```

### Notes

- Use `data-testid` in Elm for stable selectors when writing tests.
