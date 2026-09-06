import { expect, test } from "@playwright/test";

test.describe("App Sorting", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("./apps");
  });

  test("sorts apps alphabetically when requested", async ({ page }) => {
    await expect(page.getByTestId("app-result").first()).toBeVisible();

    await page.getByTestId("sort-dropdown-button").click();

    await page.getByTestId("sort-dropdown-option-alphabetical").click();

    await page.waitForTimeout(500);

    const titles = await page
      .locator("[data-testid=\"app-result\"] .item-card-title")
      .allInnerTexts();

    expect(titles.length).toBeGreaterThan(0);

    const sortedTitles = [...titles].sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));

    expect(titles).toEqual(sortedTitles);
  });

  test("reshuffles apps when standalone shuffle button is clicked", async ({ page }) => {
    await expect(page.getByTestId("app-result").first()).toBeVisible();

    // Default is random, so the shuffle button should be visible
    await expect(page.getByTestId("sort-shuffle-button")).toBeVisible();

    const initialTitles = await page
      .locator("[data-testid=\"app-result\"] .item-card-title")
      .allInnerTexts();

    expect(initialTitles.length).toBeGreaterThan(0);

    await page.getByTestId("sort-shuffle-button").click();
    await page.waitForTimeout(500);

    const shuffledTitles = await page
      .locator("[data-testid=\"app-result\"] .item-card-title")
      .allInnerTexts();

    expect(shuffledTitles).not.toEqual(initialTitles);
  });

  test("hides shuffle button when sorted alphabetically", async ({ page }) => {
    await expect(page.getByTestId("app-result").first()).toBeVisible();
    await expect(page.getByTestId("sort-shuffle-button")).toBeVisible();

    await page.getByTestId("sort-dropdown-button").click();
    await page.getByTestId("sort-dropdown-option-alphabetical").click();
    await page.waitForTimeout(500);

    await expect(page.getByTestId("sort-shuffle-button")).toBeHidden();
  });
});
