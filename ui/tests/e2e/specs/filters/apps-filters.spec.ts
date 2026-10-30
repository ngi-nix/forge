import { expect, test } from "@playwright/test";
import { TEST_APP_CATEGORY, TEST_APP_NAME, TEST_APP_SEARCH } from "../constants";

test.describe("Apps filters", () => {
  const testApp = (page) =>
    page.getByTestId("app-result").filter({ has: page.locator(`[data-app-name="${TEST_APP_NAME}"]`) }).first();

  test("a category button toggles the category filter", async ({ page }) => {
    await page.goto("./");

    const chip = page.getByTestId(`apps-filter-category-${TEST_APP_CATEGORY}`);
    await expect(chip).toHaveAttribute("aria-pressed", "false");

    await chip.click();
    await expect(chip).toHaveAttribute("aria-pressed", "true");
    await expect(page).toHaveURL(new RegExp(`[?&]c=${TEST_APP_CATEGORY}`));

    await chip.click();
    await expect(chip).toHaveAttribute("aria-pressed", "false");
    await expect(page).not.toHaveURL(/[?&]c=/);
  });

  test("a category button replaces the selected category", async ({ page }) => {
    await page.goto(`./?c=${TEST_APP_CATEGORY}`);

    const other = TEST_APP_CATEGORY === "security" ? "chat" : "security";
    await page.getByTestId(`apps-filter-category-${other}`).click();
    await expect(page.getByTestId(`apps-filter-category-${other}`)).toHaveAttribute("aria-pressed", "true");
    await expect(page.getByTestId(`apps-filter-category-${TEST_APP_CATEGORY}`)).toHaveAttribute("aria-pressed", "false");
    await expect(page).toHaveURL(new RegExp(`[?&]c=${other}(&|$)`));
  });

  test("the category filter keeps apps in that category", async ({ page }) => {
    await page.goto(`./apps?q=${TEST_APP_SEARCH}&c=${TEST_APP_CATEGORY}`);
    await expect(testApp(page)).toBeVisible();
  });

  test("the form filter removes apps of other forms", async ({ page }) => {
    // The test app is not a library.
    await page.goto(`./apps?q=${TEST_APP_SEARCH}&f=library`);
    await expect(testApp(page)).toHaveCount(0);

    // Results come back when the filter is removed and the search stays the same.
    await page.getByTestId("apps-filter-form-library").click();
    await expect(testApp(page)).toBeVisible();
  });

  test("the clear button removes all filters", async ({ page }) => {
    await page.goto(`./?c=${TEST_APP_CATEGORY}&f=library`);

    await page.getByTestId("apps-filter-clear").click();
    await expect(page).not.toHaveURL(/[?&](c|f)=/);
    await expect(page.getByTestId("apps-filter-clear")).toHaveCount(0);
  });

  test("a category link on the app page opens the filtered list", async ({ page }) => {
    await page.goto(`./app/${TEST_APP_NAME}`);

    await page.getByTestId(`app-tag-category-${TEST_APP_CATEGORY}`).click();
    await expect(page).toHaveURL(new RegExp(`[?&]c=${TEST_APP_CATEGORY}`));
    await expect(page.getByTestId(`apps-filter-category-${TEST_APP_CATEGORY}`)).toHaveAttribute("aria-pressed", "true");
  });
});
