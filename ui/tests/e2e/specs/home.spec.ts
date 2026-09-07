import { expect, test } from "@playwright/test";
import { TEST_APP_SEARCH } from "./constants";

test.describe("Home Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("./");
  });

  test("deployment reachable and Elm app mounts", async ({ page }) => {
    await expect(page).toHaveTitle(/NGI Forge/i);
  });

  test("shows list of apps", async ({ page }) => {
    const apps = page.getByTestId("app-result");
    await expect(apps.first()).toBeVisible();
  });

  test("search filters apps", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();

    await searchBar.fill(TEST_APP_SEARCH);

    const apps = page.getByTestId("app-result");
    await expect(apps.first()).toBeVisible();
  });

  test("clicking an app navigates to app details", async ({ page }) => {
    const firstApp = page.getByTestId("app-result").first();
    const href = await firstApp.locator("a").first().getAttribute("href");
    expect(href).not.toBeNull();

    await firstApp.click();
    await expect(page).toHaveURL(new RegExp(`${href?.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")}$`));
  });

  test.describe("Responsive Layouts", () => {
    const viewports = [
      { width: 320, height: 568, name: "super-tiny" },
      { width: 390, height: 844, name: "mobile" },
      { width: 768, height: 1024, name: "tablet" },
      { width: 882, height: 1024, name: "tablet-882" },
      { width: 1200, height: 1080, name: "desktop" },
      { width: 1920, height: 1080, name: "widescreen" },
    ];

    for (const vp of viewports) {
      test(`app cards do not overflow on ${vp.name} (${vp.width}px)`, async ({ page }) => {
        await page.setViewportSize({ width: vp.width, height: vp.height });
        await page.goto("./");

        const apps = page.getByTestId("app-result");
        await expect(apps.first()).toBeVisible();

        const cards = await apps.all();
        for (const card of cards) {
          const hasOverflow = await card.evaluate((el) => {
            // Check if content spills out horizontally (vertical spill is expected on tiny screens due to 1:1 aspect ratio)
            const tooltips = el.querySelectorAll(".tooltip");
            tooltips.forEach(t => (t as HTMLElement).style.display = "none");
            const isOverflow = el.scrollWidth - el.clientWidth > 1;
            tooltips.forEach(t => (t as HTMLElement).style.display = "");
            return isOverflow;
          });
          expect(hasOverflow).toBe(false);
        }
      });
    }
  });
});
