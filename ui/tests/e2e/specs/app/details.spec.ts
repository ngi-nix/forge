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

  test("shows screenshots with captions and links to the full images", async ({ page }) => {
    // mock-test in mock data has two screenshots
    const screenshots = page.getByTestId("app-screenshots");
    await expect(screenshots).toBeVisible();
    await expect(screenshots.locator("figcaption")).toHaveText(["Mock screenshot.", "Second mock screenshot."]);
    const path = `resources/apps/${TEST_APP_NAME}/screenshots`;
    for (const index of [0, 1]) {
      await expect(screenshots.locator("a").nth(index)).toHaveAttribute("href", `${path}/${index}.webp`);
      await expect(screenshots.locator("img").nth(index)).toHaveAttribute("src", `${path}/${index}-thumb.webp`);
    }
    await expect(screenshots.locator("img").first()).toHaveAttribute("alt", "Mock screenshot.");
  });

  test("shows buttons that scroll the screenshots", async ({ page }) => {
    const row = page.getByTestId("app-screenshots");
    const rowId = await row.getAttribute("id");
    // The mock screenshots are empty files. Make each one as wide as the row, thus the row can scroll.
    await row.evaluate((element) =>
      element.querySelectorAll("figure").forEach((figure) => {
        figure.style.minWidth = `${element.clientWidth}px`;
      })
    );
    const scrollLeft = () => row.evaluate((element) => element.scrollLeft);
    const next = page.getByRole("button", { name: "Show the next screenshots" });
    const previous = page.getByRole("button", { name: "Show the previous screenshots" });
    for (const button of [previous, next]) {
      await expect(button).toBeVisible();
      await expect(button).toHaveAttribute("aria-controls", rowId!);
    }
    await next.click();
    await expect.poll(scrollLeft).toBeGreaterThan(0);
    await previous.click();
    await expect.poll(scrollLeft).toBe(0);
  });

  test("shows a screenshot in full size and the next and previous screenshots", async ({ page }) => {
    const path = `resources/apps/${TEST_APP_NAME}/screenshots`;
    const modal = page.getByTestId("screenshot-modal");
    const position = page.getByTestId("screenshot-modal-position");
    await page.getByTestId("app-screenshots").locator("a").first().click();
    await expect(modal).toBeVisible();
    await expect(page).toHaveURL(/#screenshot-1$/);
    await expect(position).toHaveText("1 / 2");
    await expect(modal.locator("img")).toHaveAttribute("src", `${path}/0.webp`);
    await expect(modal).toContainText("Mock screenshot.");

    await modal.getByRole("button", { name: "Show the next screenshot" }).click();
    await expect(position).toHaveText("2 / 2");
    await expect(modal.locator("img")).toHaveAttribute("src", `${path}/1.webp`);
    await expect(page).toHaveURL(/#screenshot-2$/);
    // The screenshots wrap around.
    await page.keyboard.press("ArrowRight");
    await expect(position).toHaveText("1 / 2");
    await page.keyboard.press("ArrowLeft");
    await expect(position).toHaveText("2 / 2");

    await page.keyboard.press("Escape");
    await expect(modal).toBeHidden();

    await page.goto(`./app/${TEST_APP_NAME}#screenshot-2`);
    await expect(position).toHaveText("2 / 2");
    await modal.getByRole("button", { name: "Close" }).click();
    await expect(modal).toBeHidden();
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
      await expect(deployTooltip).toHaveText("Instructions to deploy the app in a machine");
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
