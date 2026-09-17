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

  test("shuffle tooltip is positioned correctly and within viewport bounds", async ({ page, isMobile }) => {
    await expect(page.getByTestId("app-result").first()).toBeVisible();

    const shuffleButton = page.getByTestId("sort-shuffle-button");
    await expect(shuffleButton).toBeVisible();

    // Hover over the shuffle button to show the tooltip
    await shuffleButton.hover();
    await page.waitForTimeout(500);

    const tooltip = page.locator(".shuffle-tooltip");
    await expect(tooltip).toBeVisible();

    // Verify it stays within the viewport bounds (especially important on mobile)
    const box = await tooltip.boundingBox();
    expect(box).not.toBeNull();

    const viewport = page.viewportSize();
    expect(viewport).not.toBeNull();

    expect(box!.x).toBeGreaterThanOrEqual(0); // Not overflowing left
    expect(box!.x + box!.width).toBeLessThanOrEqual(viewport!.width); // Not overflowing right

    // Check it is above the button
    const buttonBox = await shuffleButton.boundingBox();
    expect(buttonBox).not.toBeNull();
    // Tooltip bottom (y + height) should be less than or equal to button top (y)
    // with some slight tolerance in case of rounding, but usually it's strict
    expect(box!.y + box!.height).toBeLessThanOrEqual(buttonBox!.y);

    // And still inside viewport vertically
    expect(box!.y).toBeGreaterThanOrEqual(0);
  });
});
