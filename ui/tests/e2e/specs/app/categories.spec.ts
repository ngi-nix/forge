import { expect, test } from "@playwright/test";

test.describe("App Categories Filter", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("./apps");
  });

  test("can filter apps by category", async ({ page }) => {
    await expect(page.getByTestId("app-result").first()).toBeVisible();

    const categoryButton = page.getByTestId("category-filter-Office");
    await expect(categoryButton).toBeVisible();

    const initialResultsCount = await page.getByTestId("app-result").count();

    // Click category filter
    await categoryButton.click();
    await page.waitForTimeout(500);

    // Verify some results are still shown
    const filteredResultsCount = await page.getByTestId("app-result").count();
    expect(filteredResultsCount).toBeGreaterThan(0);

    // Toggle off
    await categoryButton.click();
    await page.waitForTimeout(500);

    const resetResultsCount = await page.getByTestId("app-result").count();
    expect(resetResultsCount).toEqual(initialResultsCount);
  });

  test("can search within a selected category", async ({ page }) => {
    await expect(page.getByTestId("app-result").first()).toBeVisible();

    const categoryButton = page.getByTestId("category-filter-Office");
    await expect(categoryButton).toBeVisible();

    // Click category filter
    await categoryButton.click();
    await page.waitForTimeout(500);

    const categoryResultsCount = await page.getByTestId("app-result").count();

    // Type in search bar
    const searchInput = page.getByTestId("main-search-bar");
    await expect(searchInput).toBeVisible();
    await searchInput.fill("mock");
    await page.waitForTimeout(500);

    const searchFilteredCount = await page.getByTestId("app-result").count();
    expect(searchFilteredCount).toBeGreaterThan(0);
    expect(searchFilteredCount).toBeLessThanOrEqual(categoryResultsCount);
  });
});
