import { expect, test } from "@playwright/test";
import { TEST_APP_SEARCH, TEST_RECIPE_OPTION } from "../constants";

test("search works in homepage and updates URL", async ({ page }) => {
  await page.goto("./");

  const searchBar = page.getByTestId("main-search-bar");
  await searchBar.fill(TEST_APP_SEARCH);

  const results = page.getByTestId("app-result");
  await expect(results.first()).toBeVisible();

  await expect(page).toHaveURL(new RegExp(`.*[?&]q=${TEST_APP_SEARCH}`));
});

test("homepage loads search results directly from query param", async ({ page }) => {
  await page.goto(`./apps?q=${TEST_APP_SEARCH}`);

  const searchBar = page.getByTestId("main-search-bar");
  await expect(searchBar).toHaveValue(TEST_APP_SEARCH);

  const results = page.getByTestId("app-result");
  await expect(results.first()).toBeVisible();
});

test("search works in options page and updates URL", async ({ page }) => {
  const responsePromise = page.waitForResponse((response) => response.url().includes("forge-options.json"));
  await page.goto("./recipe/options");
  await responsePromise;

  await expect(page.getByTestId("option-result").first()).toBeVisible();

  const searchTerm = TEST_RECIPE_OPTION;
  const searchBar = page.getByTestId("main-search-bar");
  await searchBar.fill(searchTerm);

  const results = page.getByTestId("option-result");
  await expect(results.first()).toBeVisible();

  const expectedParam = encodeURIComponent(searchTerm);
  await expect(page).toHaveURL(
    new RegExp(`.*[?&]q=${expectedParam.replace(/\*/g, "\\*")}`),
  );
});

test("options page loads search results directly from query param", async ({ page }) => {
  const searchTerm = TEST_RECIPE_OPTION;
  const responsePromise = page.waitForResponse((response) => response.url().includes("forge-options.json"));

  await page.goto(`./recipe/options?q=${encodeURIComponent(searchTerm)}`);
  await responsePromise;

  const searchBar = page.getByTestId("main-search-bar");
  await expect(searchBar).toHaveValue(searchTerm);

  const results = page.getByTestId("option-result");
  await expect(results.first()).toBeVisible();
});
