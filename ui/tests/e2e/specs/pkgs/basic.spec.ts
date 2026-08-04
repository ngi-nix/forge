import { expect, test } from "@playwright/test";
import { TEST_PKG_SEARCH } from "../constants";

test.describe("Packages Page", () => {
  test.beforeEach(async ({ page }) => {
    const responsePromise = page.waitForResponse((response) => response.url().includes("forge-config.json"));
    await page.goto("./pkgs");
    await responsePromise;
  });

  test("loads package results", async ({ page }) => {
    const results = page.getByTestId("pkg-result");
    await expect(results.first()).toBeVisible();
  });

  test("search filters packages", async ({ page }) => {
    const searchBar = page.getByTestId("main-search-bar");
    await expect(searchBar).toBeVisible();

    await searchBar.fill(TEST_PKG_SEARCH);

    const results = page.getByTestId("pkg-result");
    await expect(await results.count()).toBeGreaterThan(0);

    await expect(results.first()).toContainText(new RegExp(TEST_PKG_SEARCH, "i"));
  });

  test("clicking a package updates URL fragment", async ({ page }) => {
    const firstPackage = page.getByTestId("pkg-result").first();
    const packageName = await firstPackage.getAttribute("id");

    await firstPackage.click();

    await expect(page).toHaveURL(new RegExp(`#${packageName}$`));
  });

  test("clicking a package triggers highlight animation", async ({ page }) => {
    const firstPackage = page.getByTestId("pkg-result").first();
    await firstPackage.click();
    await expect(firstPackage).toHaveClass(/trigger-pulse/);
  });

  test("pagination works", async ({ page }) => {
    const nextBtn = page.getByTestId("pagination-next").first();
    const prevBtn = page.getByTestId("pagination-prev").first();
    const currentPage = page.getByTestId("pagination-current").first();

    await expect(prevBtn).toBeDisabled();
    await expect(currentPage).toHaveText("1");

    const firstPackageOnPage1 = await page.getByTestId("pkg-result").first().textContent();

    if (await nextBtn.isEnabled()) {
      await nextBtn.click();
      await expect(currentPage).toHaveText("2");
      await expect(prevBtn).not.toBeDisabled();

      const firstPackageOnPage2 = await page.getByTestId("pkg-result").first().textContent();
      expect(firstPackageOnPage1).not.toEqual(firstPackageOnPage2);

      await prevBtn.click();
      await expect(currentPage).toHaveText("1");
      await expect(prevBtn).toBeDisabled();
    }
  });

  test("manual URL pagination works", async ({ page }) => {
    await page.goto("./pkgs?page=2");
    const currentPage = page.getByTestId("pagination-current").first();
    await expect(currentPage).toHaveText("2");

    await page.goto("./pkgs?page=1");
    await expect(currentPage).toHaveText("1");
  });

  test("manual URL page-size works", async ({ page }) => {
    await page.goto("./pkgs?page-size=1");
    const results = page.getByTestId("pkg-result");
    await expect(results).toHaveCount(1);
  });
});
