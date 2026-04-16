import { expect, test } from "@playwright/test";
import { TEST_APP_NAME } from "../constants";

test.describe("Permalinks and Smooth Scrolling", () => {
  const targetPage = `./app/${TEST_APP_NAME}`;

  test("direct navigation to a hash anchor scrolls to the element", async ({ page }) => {
    await page.goto(`${targetPage}#resources`);

    const grantsSection = page.locator("#resources");

    await expect(grantsSection).toBeInViewport();
    await expect(grantsSection).toHaveClass(/trigger-pulse/);
  });
});
