import { expect, test } from "@playwright/test";

async function getVisibleAppResultsCount(page) {
  let count = 0;
  for (const el of await page.getByTestId("app-result").all()) {
    if (await el.isVisible()) count++;
  }
  return count;
}

test.describe("App Categories Filter", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("./apps");
  });

  test("can filter apps by category using dropdown", async ({ page }) => {
    await expect(page.getByTestId("app-result").first()).toBeVisible();

    const dropdownButton = page.getByTestId("category-dropdown-button");
    await expect(dropdownButton).toBeVisible();

    const initialResultsCount = await getVisibleAppResultsCount(page);

    // Open dropdown
    await dropdownButton.click();

    // Click category filter
    const categoryButton = page.getByTestId("category-filter-Office");
    await expect(categoryButton).toBeVisible();
    await categoryButton.click();
    await page.waitForTimeout(500);

    // Verify some results are still shown
    const filteredResultsCount = await getVisibleAppResultsCount(page);
    expect(filteredResultsCount).toBeGreaterThan(0);
    expect(filteredResultsCount).toBeLessThan(initialResultsCount);

    // Toggle off (All Categories)
    await dropdownButton.click();
    const allCategoriesButton = page.getByTestId("category-filter-All");
    await expect(allCategoriesButton).toBeVisible();
    await allCategoriesButton.click();
    await page.waitForTimeout(500);

    const resetResultsCount = await getVisibleAppResultsCount(page);
    expect(resetResultsCount).toEqual(initialResultsCount);
  });

  test("can search within a selected category", async ({ page }) => {
    await expect(page.getByTestId("app-result").first()).toBeVisible();

    const dropdownButton = page.getByTestId("category-dropdown-button");
    await expect(dropdownButton).toBeVisible();

    // Open dropdown and click category filter
    await dropdownButton.click();
    const categoryButton = page.getByTestId("category-filter-Office");
    await categoryButton.click();
    await page.waitForTimeout(500);

    const categoryResultsCount = await getVisibleAppResultsCount(page);

    // Type in global search bar
    const searchInput = page.getByTestId("main-search-bar");
    await expect(searchInput).toBeVisible();
    await searchInput.fill("mock");
    await page.waitForTimeout(500);

    const searchFilteredCount = await getVisibleAppResultsCount(page);
    expect(searchFilteredCount).toBeGreaterThan(0);
    expect(searchFilteredCount).toBeLessThanOrEqual(categoryResultsCount);
  });

  test("category dropdown search filters items and Escape key clears text and loses focus without closing dropdown", async ({ page }) => {
    // Open dropdown
    const dropdownButton = page.getByTestId("category-dropdown-button");
    await dropdownButton.click();

    // Find the category search input inside dropdown
    const categorySearchInput = page.locator("#category-search-input");
    await expect(categorySearchInput).toBeVisible();

    // Type "Office"
    await categorySearchInput.fill("Office");
    await page.waitForTimeout(200);

    // Verify "Office" is visible but "Science" is not
    await expect(page.getByTestId("category-filter-Office")).toBeVisible();
    await expect(page.getByTestId("category-filter-Science")).not.toBeVisible();

    // Press Escape
    await categorySearchInput.press("Escape");
    await page.waitForTimeout(200);

    // Dropdown should still be open (the input is still visible)
    await expect(categorySearchInput).toBeVisible();

    // Search text should be empty
    await expect(categorySearchInput).toHaveValue("");

    // Both should be visible now because filter is cleared
    await expect(page.getByTestId("category-filter-Office")).toBeVisible();
    await expect(page.getByTestId("category-filter-Science")).toBeVisible();
  });

  test("Escape key closes dropdown when category search is empty", async ({ page }) => {
    // Open dropdown
    const dropdownButton = page.getByTestId("category-dropdown-button");
    await dropdownButton.click();

    const categorySearchInput = page.locator("#category-search-input");
    await expect(categorySearchInput).toBeVisible();

    // Press Escape when empty
    await categorySearchInput.press("Escape");
    await page.waitForTimeout(200);

    // Dropdown should be closed (input hidden)
    await expect(categorySearchInput).not.toBeVisible();
  });

  test("ambient typing focuses category search when dropdown is open", async ({ page }) => {
    // Ensure we are focused on body
    await page.locator("body").click();

    // Open dropdown
    const dropdownButton = page.getByTestId("category-dropdown-button");
    await dropdownButton.click();

    const categorySearchInput = page.locator("#category-search-input");
    await expect(categorySearchInput).toBeVisible();

    // Ambient type 'O'
    await page.keyboard.press("O");
    await page.waitForTimeout(200);

    // Verify category search gets the text and is focused
    await expect(categorySearchInput).toHaveValue("O");
    await expect(categorySearchInput).toBeFocused();

    // Type another letter 'f' while focused
    await page.keyboard.press("f");
    await page.waitForTimeout(200);

    await expect(categorySearchInput).toHaveValue("Of");
  });
});
