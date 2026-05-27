import { expect, test } from "@playwright/test";
import { TEST_RECIPE_OPTION } from "../constants";

test.describe("Recipe Options Page", () => {
  test.beforeEach(async ({ page }) => {
    const responsePromise = page.waitForResponse((response) => response.url().includes("forge-options.json"));
    await page.goto("./recipe/options");
    await responsePromise;
  });

  test("loads recipe options", async ({ page }) => {
    const results = page.getByTestId("option-result");
    await expect(results.first()).toBeVisible();
  });

  test("search filters options", async ({ page }) => {
    const searchTerm = TEST_RECIPE_OPTION;
    const searchBar = page.getByTestId("main-search-bar");
    await searchBar.fill(searchTerm);

    const results = page.getByTestId("option-result");
    await expect(await results.count()).toBeGreaterThan(0);
    await expect(results.first()).toContainText(searchTerm);
  });

  test("clicking an option updates URL fragment", async ({ page }) => {
    const firstOption = page.getByTestId("option-result").first();
    const optionName = await firstOption.getAttribute("id");

    await firstOption.click();

    const escapedOptionName = encodeURI(optionName)?.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    await expect(page).toHaveURL(new RegExp(`#${escapedOptionName}$`));
  });

  test("pagination works", async ({ page }) => {
    const nextBtn = page.getByTestId("pagination-next").first();
    const prevBtn = page.getByTestId("pagination-prev").first();
    const currentPage = page.getByTestId("pagination-current").first();

    await expect(prevBtn).toBeDisabled();
    await expect(currentPage).toHaveText("1");

    const firstOptionOnPage1 = await page.getByTestId("option-result").first().textContent();

    if (await nextBtn.isEnabled()) {
      await nextBtn.click();
      await expect(currentPage).toHaveText("2");
      await expect(prevBtn).not.toBeDisabled();

      const firstOptionOnPage2 = await page.getByTestId("option-result").first().textContent();
      expect(firstOptionOnPage1).not.toEqual(firstOptionOnPage2);

      await prevBtn.click();
      await expect(currentPage).toHaveText("1");
      await expect(prevBtn).toBeDisabled();
    }
  });
});
