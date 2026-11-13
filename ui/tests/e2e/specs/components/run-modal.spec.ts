import { expect, test } from "@playwright/test";
import { TEST_APP_NAME, TEST_WASM_APP_NAME } from "../constants";

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

  test("direct visit to #run-browser opens modal with Browser tab active", async ({ page }) => {
    await page.goto(`${targetPage}#run-browser`);
    const modal = page.getByTestId("run-modal-container");
    await expect(modal).toBeVisible();

    const browserTab = page.getByRole("tab", { name: /browser/i });
    await expect(browserTab).toHaveClass(/active/);

    const vmLink = modal.getByTestId("run-browser-vm");
    await expect(vmLink).toHaveAttribute("href", /^https:\/\/trynix\.dev\/\?path=%2Fnix%2Fstore%2F/);
    await expect(vmLink).toHaveAttribute("href", /&cache=https%3A%2F%2Fngi-forge\.cachix\.org%20/);
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

test.describe("Browser runtime", () => {
  test("runs the example of the WASI program", async ({ page }) => {
    // eslint-disable-next-line playwright/no-skipped-test
    test.skip(TEST_WASM_APP_NAME === "", "No app with a WASI program");
    await page.goto(`./app/${TEST_WASM_APP_NAME}#run-browser`);
    const modal = page.getByTestId("run-modal-container");
    await expect(modal.getByTestId("run-browser-args")).toBeVisible();

    await modal.getByTestId("run-browser-start").click();
    await expect(modal.getByTestId("run-browser-output")).toContainText("Exit code 0", { timeout: 30000 });
    await expect(modal.getByTestId("run-browser-start")).toBeVisible();
  });
});
