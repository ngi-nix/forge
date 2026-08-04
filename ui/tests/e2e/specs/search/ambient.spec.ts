import { expect, test } from "@playwright/test";
import { TEST_APP_NAME, TEST_APP_SEARCH, TEST_RECIPE_OPTION } from "../constants";

test.describe("Ambient Search in Home page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("./");
  });

  test("typing anywhere auto-focuses the search bar and captures the key", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();

    await page.locator("body").click();

    await page.keyboard.press("n");

    await expect(searchBar).toBeFocused();
    await expect(searchBar).toHaveValue("n");
  });

  test("pressing / focuses the search bar", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).not.toBeFocused();

    await page.keyboard.press("/");
    await expect(searchBar).toBeFocused();
  });

  test("modifier key combinations do not trigger ambient search", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();
    await expect(searchBar).not.toBeFocused();

    await page.locator("body").click();

    await page.keyboard.press("Meta+c");
    await expect(searchBar).not.toBeFocused();
    await expect(searchBar).toHaveValue("");

    await page.keyboard.press("Control+c");
    await expect(searchBar).not.toBeFocused();
    await expect(searchBar).toHaveValue("");

    await page.keyboard.press("Meta+f");
    await expect(searchBar).not.toBeFocused();
    await expect(searchBar).toHaveValue("");

    await page.keyboard.press("Alt+f");
    await expect(searchBar).not.toBeFocused();
    await expect(searchBar).toHaveValue("");
  });

  test("a full search can be done via ambient key presses", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();

    await page.locator("body").click();

    await page.keyboard.type("p");

    await expect(searchBar).toBeFocused();

    // page.keyboard.type is too fast for Elm update so add a delay
    // delay 30, 100, 200 was not enough
    // await page.keyboard.type(TEST_APP_SEARCH, { delay: 200 });
    await searchBar.fill(TEST_APP_SEARCH);

    await expect(searchBar).toHaveValue(TEST_APP_SEARCH);

    const results = page.getByTestId("app-result");
    await expect(results).toHaveCount(1);
  });

  test("esc key should clear the search field", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();

    await page.locator("body").click();

    await page.keyboard.type("f");

    await expect(searchBar).toBeFocused();

    await searchBar.fill("foo:bar:baz");

    await expect(searchBar).toHaveValue("foo:bar:baz");

    let results = page.getByTestId("app-result");
    await expect(results).toHaveCount(0);

    await page.keyboard.press("Escape");
    await expect(searchBar).toHaveValue("");

    results = page.getByTestId("app-result");
    await expect(await results.count()).toBeGreaterThan(0);
  });
});

test.describe("Ambient Search in App page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(`./app/${TEST_APP_NAME}`);
  });

  test("ambient search works in app page", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();

    await page.locator("body").click();

    await page.keyboard.press("n");

    await expect(searchBar).toBeFocused();
    await expect(searchBar).toHaveValue("n");
  });

  test("ambient search is disabled when a modal is open", async ({ page }) => {
    const runBtn = page.getByTestId("app-run-button");
    await expect(runBtn).toBeVisible();
    await runBtn.click();

    const modal = page.getByTestId("run-modal-container");
    await expect(modal).toBeVisible();

    await page.keyboard.press("n");

    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).not.toBeFocused();
  });

  test("esc key will bring it back to app page for single keypress", async ({ page }) => {
    const currentAppPage = page.url();
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();

    await page.locator("body").click();

    await page.keyboard.press("n");

    await expect(searchBar).toBeFocused();
    await expect(searchBar).toHaveValue("n");

    await page.keyboard.press("Escape");
    await expect(searchBar).toHaveValue("");

    await expect(page).toHaveURL(currentAppPage);
  });

  test("esc key will bring it to apps list view after typing a word", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();

    await page.locator("body").click();

    await page.keyboard.press("s");

    await expect(searchBar).toBeFocused();

    await searchBar.fill("something");

    await expect(searchBar).toHaveValue("something");

    await page.keyboard.press("Escape");
    await expect(searchBar).toHaveValue("");

    const results = page.getByTestId("app-result");
    await expect(await results.count()).toBeGreaterThan(0);
  });

  test("typing on an app page focuses then redirects to search results", async ({ page }) => {
    await page.goto(`./app/${TEST_APP_NAME}`);
    const searchBar = page.getByTestId("main-search-bar");

    await page.keyboard.press("x");
    await expect(searchBar).toBeFocused();
    await expect(searchBar).toHaveValue("x");

    await page.keyboard.type("y");

    await expect(page).toHaveURL(/apps\?q=xy/);
    await expect(searchBar).toHaveValue("xy");
    await expect(searchBar).toBeFocused();
  });
});

test.describe("Ambient Search in Recipe Options page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("./recipe/options");
  });

  test("typing anywhere auto-focuses the search bar and captures the key", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();

    await page.locator("body").click();

    await page.keyboard.press("a");

    await expect(searchBar).toBeFocused();
    await expect(searchBar).toHaveValue("a");

    await searchBar.fill(TEST_RECIPE_OPTION);

    await expect(searchBar).toHaveValue(TEST_RECIPE_OPTION);

    const results = page.getByTestId("option-result");
    await expect(results).toHaveCount(1);
  });
});
