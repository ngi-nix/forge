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

    const recipeLink = resources.locator("a", { hasText: /Forge Recipe/i });
    await expect(recipeLink).toBeVisible();
    await expect(recipeLink).toHaveAttribute("href", new RegExp(`blob/.*/recipes/apps/${TEST_APP_NAME}/recipe.nix`));
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

  test("shows tooltips for Run and Deploy buttons on hover", async ({ page }) => {
    const runBtn = page.getByTestId("app-run-button");
    await expect(runBtn).toBeVisible();

    const runTooltip = page.getByTestId("app-run-tooltip");
    await expect(runTooltip).toBeHidden();

    await runBtn.hover();
    await expect(runTooltip).toBeVisible();
    await expect(runTooltip).toHaveText("Instructions to run/try the app without installation");

    const deployBtn = page.getByTestId("app-deploy-button");
    if (await deployBtn.isVisible()) {
      const deployTooltip = page.getByTestId("app-deploy-tooltip");
      await expect(deployTooltip).toBeHidden();

      await deployBtn.hover();
      await expect(deployTooltip).toBeVisible();
      await expect(deployTooltip).toHaveText("Instructions to install the app in a machine");
    }
  });

  test("tooltips are positioned correctly above buttons and within viewport bounds", async ({ page }) => {
    const runBtn = page.getByTestId("app-run-button");
    await expect(runBtn).toBeVisible();

    await runBtn.hover();
    const runTooltip = page.getByTestId("app-run-tooltip");
    await expect(runTooltip).toBeVisible();

    const runBox = await runTooltip.boundingBox();
    const runBtnBox = await runBtn.boundingBox();
    const viewport = page.viewportSize();

    expect(runBox).not.toBeNull();
    expect(runBtnBox).not.toBeNull();
    expect(viewport).not.toBeNull();

    // Check it is above the button
    expect(runBox!.y + runBox!.height).toBeLessThanOrEqual(runBtnBox!.y);
    expect(runBox!.y).toBeGreaterThanOrEqual(0);

    // Check horizontal bounds
    expect(runBox!.x).toBeGreaterThanOrEqual(0);
    expect(runBox!.x + runBox!.width).toBeLessThanOrEqual(viewport!.width);

    const deployBtn = page.getByTestId("app-deploy-button");
    if (await deployBtn.isVisible()) {
      await deployBtn.hover();
      const deployTooltip = page.getByTestId("app-deploy-tooltip");
      await expect(deployTooltip).toBeVisible();

      const deployBox = await deployTooltip.boundingBox();
      const deployBtnBox = await deployBtn.boundingBox();

      expect(deployBox).not.toBeNull();
      expect(deployBtnBox).not.toBeNull();

      expect(deployBox!.y + deployBox!.height).toBeLessThanOrEqual(deployBtnBox!.y);
      expect(deployBox!.y).toBeGreaterThanOrEqual(0);

      expect(deployBox!.x).toBeGreaterThanOrEqual(0);
      expect(deployBox!.x + deployBox!.width).toBeLessThanOrEqual(viewport!.width);
    }
  });
});
