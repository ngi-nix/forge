import { expect, test } from "@playwright/test";
import { TEST_APP_NAME } from "../constants";

test.describe("Deploy Modal and Hash State", () => {
  const targetPage = `./app/${TEST_APP_NAME}`;

  test("clicking Deploy opens modal and updates URL to #deploy-nixos", async ({ page }) => {
    await page.goto(targetPage);
    await page.getByTestId("app-deploy-button").click();

    await expect(page.getByTestId("deploy-modal-container")).toBeVisible();
    expect(page.url()).toContain("#deploy-nixos");
  });

  test("direct visit to #deploy-nixos opens the modal", async ({ page }) => {
    await page.goto(`${targetPage}#deploy-nixos`);
    await expect(page.getByTestId("deploy-modal-container")).toBeVisible();
  });

  test("deploy modal shows the NixOS module flake.nix snippet", async ({ page }) => {
    await page.goto(`${targetPage}#deploy-nixos`);
    const modal = page.getByTestId("deploy-modal-container");
    await expect(modal).toBeVisible();
    await expect(modal).toContainText("Create a NixOS system configuration file");
    await expect(modal.locator("pre").first()).toContainText("flake.nix");
  });

  test("deploy modal shows the check configuration instruction", async ({ page }) => {
    await page.goto(`${targetPage}#deploy-nixos`);
    const modal = page.getByTestId("deploy-modal-container");
    await expect(modal).toBeVisible();
    await expect(modal).toContainText("Check the configuration");
    await expect(modal.locator("pre").nth(1)).toContainText(
      "nix eval .#nixosConfigurations." + TEST_APP_NAME + ".config.system.build.toplevel",
    );
  });

  test("deploy modal shows the VM test instruction", async ({ page }) => {
    await page.goto(`${targetPage}#deploy-nixos`);
    const modal = page.getByTestId("deploy-modal-container");
    await expect(modal).toBeVisible();
    await expect(modal).toContainText("Test configuration in a VM");
    await expect(modal.locator("pre").nth(2)).toContainText(
      "nix run .#nixosConfigurations." + TEST_APP_NAME + ".config.system.build.vm",
    );
  });

  test("deploy modal shows the disk image instruction for the selected variant", async ({ page }) => {
    await page.goto(`${targetPage}#deploy-nixos`);
    const modal = page.getByTestId("deploy-modal-container");
    await expect(modal).toBeVisible();
    await expect(modal).toContainText("Build a disk image of the configuration");

    const variantSelect = modal.getByTestId("deploy-nixos-image-variant");
    const imageCommand = "nix build .#nixosConfigurations." + TEST_APP_NAME + ".config.system.build.images.";
    await expect(variantSelect).toHaveValue("qemu");
    await expect(modal.locator("pre").last()).toContainText(imageCommand + "qemu");

    await variantSelect.selectOption("amazon");
    await expect(modal.locator("pre").last()).toContainText(imageCommand + "amazon");
  });

  test("modal closes via Escape, close button, and backdrop click", async ({ page }) => {
    const modal = page.getByTestId("deploy-modal-container");

    await page.goto(`${targetPage}#deploy-nixos`);
    await expect(modal).toBeVisible();
    await page.getByTestId("close-deploy-modal-button").click();
    await expect(modal).toBeHidden();
    expect(page.url()).not.toContain("#deploy-nixos");

    await page.goto(`${targetPage}#deploy-nixos`);
    await expect(modal).toBeVisible();
    await page.keyboard.press("Escape");
    await expect(modal).toBeHidden();

    await page.goto(`${targetPage}#deploy-nixos`);
    await expect(modal).toBeVisible();
    await page.mouse.click(1, 1);
    await expect(modal).toBeHidden();
  });

  test("Run modal no longer shows the NixOS module section", async ({ page }) => {
    await page.goto(`${targetPage}#run-nixos`);
    const modal = page.getByTestId("run-modal-container");
    await expect(modal).toBeVisible();
    await expect(modal).not.toContainText("Enable module in a NixOS configuration");
  });
});
