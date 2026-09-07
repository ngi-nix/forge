import { expect, test } from "@playwright/test";

test.describe("Card Selection and Clicking", () => {
  test("should allow text selection without navigating, but click should navigate", async ({ page, isMobile }) => {
    await page.goto("/recipe/options?p=apps&p=pkgs");
    await page.waitForSelector(".min-vh-100");
    await page.waitForSelector("[data-testid=\"option-result\"]");
    await page.waitForTimeout(2000);

    const initialUrl = page.url();

    const firstOption = page.locator("[data-testid=\"option-result\"]").first();
    const typeElement = firstOption.locator(".option-type");

    if (!isMobile) {
      // 1. Try to select text on the option type
      const box = await typeElement.boundingBox();
      expect(box).not.toBeNull();

      // Simulate mouse drag to select text
      await page.mouse.move(box!.x + 10, box!.y + box!.height / 2);
      await page.mouse.down();
      await page.mouse.move(box!.x + box!.width - 10, box!.y + box!.height / 2, { steps: 5 });
      await page.mouse.up();

      // Wait a moment to see if it navigates (it shouldn't)
      await page.waitForTimeout(500);
      expect(page.url()).toBe(initialUrl);

      // Verify text is actually selected in the browser
      const selection = await page.evaluate(() => window.getSelection()?.toString());
      console.log("Selection was: ", selection);
      expect(selection?.trim().length).toBeGreaterThan(0);
    }

    // 2. Try to click the card anywhere (not on the link) to see if it navigates
    // Clear the selection first, because Playwright mobile might retain it
    await page.evaluate(() => window.getSelection()?.removeAllRanges());

    // We'll click near the top left of the card
    await firstOption.click({ position: { x: 5, y: 5 }, force: true });

    // It should navigate now
    await page.waitForTimeout(1000);
    expect(page.url()).not.toBe(initialUrl);
  });
});

test.describe("App Card Selection and Clicking", () => {
  test("should allow text selection without navigating, but click should navigate", async ({ page, isMobile }) => {
    await page.goto("./apps");
    await page.waitForSelector(".min-vh-100");
    await page.waitForSelector("[data-testid=\"app-result\"]");
    await page.waitForTimeout(2000);

    const initialUrl = page.url();

    const firstOption = page.locator("[data-testid=\"app-result\"]").first();
    const description = firstOption.locator(".m-item-card-description");

    if (!isMobile) {
      // 1. Try to select text on the description of an app card
      const box = await description.boundingBox();
      expect(box).not.toBeNull();

      // Simulate mouse drag to select text
      await page.mouse.move(box!.x + 10, box!.y + box!.height / 2);
      await page.mouse.down();
      await page.mouse.move(box!.x + box!.width - 10, box!.y + box!.height / 2, { steps: 5 });
      await page.mouse.up();

      // Wait a moment to see if it navigates (it shouldn't)
      await page.waitForTimeout(500);
      expect(page.url()).toBe(initialUrl);

      // Verify text is actually selected in the browser
      const selection = await page.evaluate(() => window.getSelection()?.toString());
      console.log("App Selection was: ", selection);
      expect(selection?.trim().length).toBeGreaterThan(0);
    }

    // 2. Try to click the card anywhere (not on the link) to see if it navigates
    // Clear the selection first, because Playwright mobile might retain it
    await page.evaluate(() => window.getSelection()?.removeAllRanges());

    // We'll click near the top left of the card
    await firstOption.click({ position: { x: 5, y: 5 }, force: true });

    // It should navigate now
    await page.waitForTimeout(1000);
    expect(page.url()).not.toBe(initialUrl);
  });
});
