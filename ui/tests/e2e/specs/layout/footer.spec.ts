import { expect, test } from "@playwright/test";

test.describe("Footer", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("./");
  });

  test("contains correct repository and version links", async ({ page }) => {
    const footer = page.locator("footer");
    await expect(footer).toBeVisible();

    const repoLink = footer.getByRole("link", { name: "ngi-nix/forge" });
    await expect(repoLink).toBeVisible();

    const versionLink = footer.locator("span:has-text('Version') a");
    await expect(versionLink).toBeVisible();
    const versionText = (await versionLink.textContent())?.trim();

    if (versionText === "master") {
      await expect(versionLink).toHaveAttribute("href", /.*\/tree\/master/);
    } else {
      expect(versionText).toMatch(/^[0-9a-f]{7,8}$/);
      await expect(versionLink).toHaveAttribute("href", new RegExp(`.*/tree/.*${versionText}`));
    }
  });

  test("contains contact links in second footer", async ({ page }) => {
    const footer = page.locator("footer");
    await expect(footer).toBeVisible();

    await expect(footer.getByText("Connect with us:")).toBeVisible();
  });
});
