import { expect, test } from "@playwright/test";

/* We have hidden cards to occupy space in the UI, so filter only visible cards */
async function getVisibleAppResultsCount(page) {
  let count = 0;
  for (const el of await page.getByTestId("app-result").all()) {
    if (await el.isVisible()) count++;
  }
  return count;
}

test.describe("App Categories Filtering", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("./apps");
  });

  test("can filter apps by category using dropdown", async ({ page }) => {
    await expect(page.getByTestId("app-result").first()).toBeVisible();

    const dropdownButton = page.getByTestId("category-dropdown-button");
    await expect(dropdownButton).toBeVisible();

    const initialResultsCount = await getVisibleAppResultsCount(page);

    await dropdownButton.click();

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

  test("category search input is auto-focused when dropdown opens", async ({ page }) => {
    const dropdownButton = page.getByTestId("category-dropdown-button");
    await dropdownButton.click();

    const categorySearchInput = page.locator("#category-search-input");
    await expect(categorySearchInput).toBeVisible();
    await expect(categorySearchInput).toBeFocused();
  });

  test("All Categories dynamically moves to bottom when searching", async ({ page }) => {
    const dropdownButton = page.getByTestId("category-dropdown-button");
    await dropdownButton.click();

    // Find the category menu items container (the list of buttons)
    // To do this, we can locate all category buttons and check their order

    // Initially, All Categories should be first
    let buttons = await page.locator("[data-testid^=\"category-filter-\"]").all();
    expect(await buttons[0].getAttribute("data-testid")).toBe("category-filter-All");

    // Type in the search input
    const categorySearchInput = page.locator("#category-search-input");
    await categorySearchInput.fill("Office");
    await page.waitForTimeout(200);

    // After searching, All Categories should be the last item
    buttons = await page.locator("[data-testid^=\"category-filter-\"]").all();
    const lastButton = buttons[buttons.length - 1];
    expect(await lastButton.getAttribute("data-testid")).toBe("category-filter-All");

    // Verify Office is visible before it
    expect(buttons.length).toBeGreaterThan(1);
    expect(await buttons[0].getAttribute("data-testid")).toBe("category-filter-Office");
  });

  test("dropdown supports keyboard navigation (Arrow keys and Enter) and auto-scrolls", async ({ page }) => {
    const dropdownButton = page.getByTestId("category-dropdown-button");
    await dropdownButton.click();

    const categorySearchInput = page.locator("#category-search-input");
    await expect(categorySearchInput).toBeFocused();

    // Initial focus should be on "All Categories" (the first item) since it's the active one
    let allButton = page.getByTestId("category-filter-All");
    await expect(allButton).toHaveClass(/active/);
    await expect(allButton).toHaveClass(/keyboard-focused/); // Our new focus class

    // Press ArrowDown
    await categorySearchInput.press("ArrowDown");
    await page.waitForTimeout(100);

    // The second item should now be focused
    let buttons = await page.locator("[data-testid^=\"category-filter-\"]").all();
    expect(buttons.length).toBeGreaterThan(1);
    await expect(buttons[1]).toHaveClass(/keyboard-focused/);
    await expect(buttons[0]).not.toHaveClass(/keyboard-focused/);

    // Press Enter to select the second item
    await categorySearchInput.press("Enter");
    await page.waitForTimeout(500);

    // Dropdown should close and the filter should apply
    await expect(categorySearchInput).not.toBeVisible();

    // Re-open dropdown to check initial focus
    await dropdownButton.click();
    await expect(categorySearchInput).toBeVisible();
    await page.waitForTimeout(200); // Allow scroll into view

    // The previously selected item should immediately be focused
    buttons = await page.locator("[data-testid^=\"category-filter-\"]").all();
    await expect(buttons[1]).toHaveClass(/keyboard-focused/);
    await expect(buttons[0]).not.toHaveClass(/keyboard-focused/);
  });
});

test("can clear category filter using the explicit clear button", async ({ page }) => {
  // Open dropdown and click category filter
  const dropdownButton = page.getByTestId("category-dropdown-button");
  await dropdownButton.click();
  const categoryButton = page.getByTestId("category-filter-Office");
  await expect(categoryButton).toBeVisible();
  await categoryButton.click();

  // Verify it is filtered
  await expect(page).toHaveURL(/.*category=Office.*/);

  // Clear button should be visible
  const clearButton = page.getByTestId("clear-category-button");
  await expect(clearButton).toBeVisible();

  // Click clear button
  await clearButton.click();

  // Verify URL no longer contains category
  await expect(page).not.toHaveURL(/.*category=Office.*/);

  // Verify clear button is now hidden
  await expect(clearButton).toBeHidden();
});
