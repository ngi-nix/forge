import { expect, test } from "@playwright/test";

test("theme toggles between dark and light and updates icons", async ({ page, isMobile }) => {
  await page.goto("./");

  const html = page.locator("html");

  if (isMobile) {
    const navToggler = page.getByTestId("navbar-toggler");
    await navToggler.click();
  }

  // nth(i) will get the nth match
  // for playwright there is a strict mode where getByTestId should only match 1 entry
  // but because we have two theme switcher buttons (one always hidden in nav collapse)
  // we need to chose the correct selector for mobile and desktop
  const index = isMobile ? 1 : 0;

  const toggleBtn = page.getByTestId("theme-toggle-btn").nth(index);
  const sunIcon = page.getByTestId("icon-sun").nth(index);
  const moonIcon = page.getByTestId("icon-moon").nth(index);

  // only works because we set colorScheme in playwright.config.ts
  await expect(html).toHaveAttribute("data-bs-theme", "dark");
  await expect(moonIcon).toBeVisible();
  await expect(sunIcon).toBeHidden();

  await toggleBtn.click();
  await expect(html).toHaveAttribute("data-bs-theme", "light");
  await expect(sunIcon).toBeVisible();
  await expect(moonIcon).toBeHidden();

  await toggleBtn.click();
  await expect(html).toHaveAttribute("data-bs-theme", "dark");
  await expect(moonIcon).toBeVisible();
  await expect(sunIcon).toBeHidden();
});
