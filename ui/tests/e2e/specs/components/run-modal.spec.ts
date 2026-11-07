import { expect, test } from "@playwright/test";
import { TEST_APP_NAME, TEST_PARAMETER, TEST_PARAMETER_APP_NAME, TEST_PARAMETER_FLAG } from "../constants";

test.describe("Run Modal and Hash State", () => {
  const targetPage = `./app/${TEST_APP_NAME}`;

  test("clicking Run opens modal and updates URL to #run", async ({ page }) => {
    await page.goto(targetPage);
    await page.getByTestId("app-run-button").click();

    await expect(page.getByTestId("run-modal-container")).toBeVisible();
    expect(page.url()).toContain("#run");
  });

  test("direct visit to #run opens the modal", async ({ page }) => {
    await page.goto(`${targetPage}#run`);
    await expect(page.getByTestId("run-modal-container")).toBeVisible();
  });

  test("direct visit to #run-shell opens modal with Shell tab active", async ({ page }) => {
    await page.goto(`${targetPage}#run-shell`);
    await expect(page.getByTestId("run-modal-container")).toBeVisible();

    const shellTab = page.getByRole("tab", { name: /shell/i });
    await expect(shellTab).toHaveClass(/active/);
  });

  test("Container tab shows how to configure the services", async ({ page }) => {
    await page.goto(`./app/${TEST_PARAMETER_APP_NAME}#run-container`);

    const configure = page.getByTestId("run-container-configure");
    await configure.getByText("Configure services").click();
    await expect(configure).toContainText(TEST_PARAMETER);
    await expect(configure).toContainText("--forge-help");
    await expect(configure).toContainText(TEST_PARAMETER_FLAG);
  });

  test("modal closes via Escape, close button, and backdrop click", async ({ page }) => {
    const modal = page.getByTestId("run-modal-container");

    await page.goto(`${targetPage}#run`);
    await expect(modal).toBeVisible();
    await page.getByTestId("close-modal-button").click();
    await expect(modal).toBeHidden();
    expect(page.url()).not.toContain("#run");

    await page.goto(`${targetPage}#run`);
    await expect(modal).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(modal).toBeHidden();

    await page.goto(`${targetPage}#run`);
    await expect(modal).toBeVisible();
    await page.mouse.click(1, 1);
    await expect(modal).toBeHidden();
  });

  test("shows flake commands and no traditional switcher", async ({ page }) => {
    await page.goto(`${targetPage}#run-shell`);
    const modal = page.getByTestId("run-modal-container");
    await expect(modal).toBeVisible();

    // Verify Flakes command is shown
    await expect(modal.locator("pre").last()).toContainText("nix shell");

    // Verify there is no Flakes/Traditional switcher
    await expect(modal.getByRole("button", { name: /flakes/i })).toHaveCount(0);
    await expect(modal.getByRole("button", { name: /traditional/i })).toHaveCount(0);
  });

  test("handles existing preferences with install key in localStorage without crashing", async ({ page }) => {
    // Seed localStorage with legacy preferences before navigation
    await page.addInitScript(() => {
      localStorage.setItem(
        "preferences",
        JSON.stringify({ install: "nix_traditional", theme: "dark", sort: "random" }),
      );
    });

    await page.goto(`${targetPage}#run-shell`);
    const modal = page.getByTestId("run-modal-container");
    await expect(modal).toBeVisible();

    // Verify app runs, decodes preferences without crash, and shows flake commands
    await expect(modal.locator("pre").last()).toContainText("nix shell");
  });

  test("copy button works and copies the command", async ({ context, page, browserName }) => {
    // eslint-disable-next-line playwright/no-skipped-test
    test.skip(browserName !== "chromium", "Clipboard permissions only supported in Chromium");
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);

    await page.goto(`${targetPage}#run-shell`);
    const modal = page.getByTestId("run-modal-container");
    await expect(modal).toBeVisible();

    const copyBtn = modal.locator("button.copy").last();

    await copyBtn.click();
    await expect(copyBtn).toHaveClass(/active/);

    await expect(async () => {
      const clipboardText = await page.evaluate(() => navigator.clipboard.readText());
      expect(clipboardText).toMatch("nix shell");
    }).toPass();
  });
});
