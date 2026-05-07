import { expect, test } from "@playwright/test";
import { TEST_APP_NAME } from "../constants";

test.describe("App Details Page", () => {
  const targetApp = TEST_APP_NAME;

  test.beforeEach(async ({ page }) => {
    await page.goto(`./app/${targetApp}`);
  });

  test("shows app title and description", async ({ page }) => {
    await expect(page.getByTestId("app-title")).toBeVisible();
    await expect(page.getByTestId("app-description")).toBeVisible();
  });

  test("shows resources section with links", async ({ page }) => {
    const resources = page.locator("#resources");
    await expect(resources).toBeVisible();

    const links = resources.locator("a");
    await expect(await links.count()).toBeGreaterThan(0);

    await expect(resources).toContainText(/Forge Recipe/i);
  });

  test("shows NGI grants section if available", async ({ page }) => {
    // mock-test in mock data has grants
    const grants = page.locator("#grants");
    await expect(grants).toBeVisible();
    await expect(grants).toContainText(/NGI Grants/i);
  });

  test("navigation via resources anchor link", async ({ page }) => {
    const resourcesAnchor = page.locator("#resources .anchor-link");
    await resourcesAnchor.click();
    await expect(page).toHaveURL(new RegExp(`#resources$`));
  });
});
