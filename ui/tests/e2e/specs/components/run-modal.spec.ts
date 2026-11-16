import { expect, test } from "@playwright/test";
import { readFile } from "node:fs/promises";
import {
  TEST_APP_NAME,
  TEST_WASM_APP_NAME,
  TEST_WASM_BZIP2_APP_NAME,
  TEST_WASM_CPDF_APP_NAME,
  TEST_WASM_FILES_APP_NAME,
} from "../constants";

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

  test("runs the WASI program with an added file", async ({ page }) => {
    // eslint-disable-next-line playwright/no-skipped-test
    test.skip(TEST_WASM_APP_NAME !== "jaq", "The test uses the arguments of jaq");
    await page.goto(`./app/${TEST_WASM_APP_NAME}#run-browser`);
    const modal = page.getByTestId("run-modal-container");

    await modal.getByTestId("run-browser-files").setInputFiles({
      name: "added.json",
      mimeType: "application/json",
      buffer: Buffer.from("{\"added\": \"from-file\"}"),
    });
    const file = modal.getByTestId("run-browser-file").filter({ hasText: "added.json" });
    await expect(file).toBeVisible();
    await expect(file.getByTestId("run-browser-file-download")).toHaveAttribute("href", /^blob:/);
    await expect(file.getByTestId("run-browser-file-new")).toHaveCount(0);

    await modal.getByTestId("run-browser-args").fill(".added added.json");
    await modal.getByTestId("run-browser-start").click();
    await expect(modal.getByTestId("run-browser-output")).toContainText("Exit code 0", { timeout: 30000 });
    await expect(modal.getByTestId("run-browser-output")).toContainText("from-file");

    await file.getByTestId("run-browser-file-remove").click();
    await expect(file).toHaveCount(0);
  });

  test("runs the WASI program that writes a file", async ({ page }) => {
    // eslint-disable-next-line playwright/no-skipped-test
    test.skip(TEST_WASM_FILES_APP_NAME === "", "No app with example files");
    await page.goto(`./app/${TEST_WASM_FILES_APP_NAME}#run-browser`);
    const modal = page.getByTestId("run-modal-container");
    await expect(modal.getByTestId("run-browser-file").filter({ hasText: "sample.typ" })).toBeVisible();

    await modal.getByTestId("run-browser-start").click();
    await expect(modal.getByTestId("run-browser-output")).toContainText("Exit code 0", { timeout: 30000 });
    const output = modal.getByTestId("run-browser-file").filter({ hasText: "sample.pdf" });
    await expect(output.getByTestId("run-browser-file-new")).toBeVisible();
    await expect(output.getByTestId("run-browser-file-open")).toHaveAttribute("href", /^blob:/);
    const input = modal.getByTestId("run-browser-file").filter({ hasText: "sample.typ" });
    await expect(input.getByTestId("run-browser-file-new")).toHaveCount(0);
    await expect(input.getByTestId("run-browser-file-open")).toHaveCount(0);

    const changed = modal.getByTestId("run-browser-changed-files");
    await expect(changed).toContainText("sample.pdf");
    await expect(changed).not.toContainText("sample.typ");
    const downloadPromise = page.waitForEvent("download");
    await changed.getByTestId("run-browser-file-download").click();
    const download = await downloadPromise;
    expect(download.suggestedFilename()).toBe("sample.pdf");
    const bytes = await readFile(await download.path());
    expect(bytes.subarray(0, 5).toString()).toBe("%PDF-");
  });

  // `bzip2` sets the times of the files that it writes.
  test("runs the WASI program that sets the times of a file", async ({ page }) => {
    // eslint-disable-next-line playwright/no-skipped-test
    test.skip(TEST_WASM_BZIP2_APP_NAME === "", "No app with bzip2");
    await page.goto(`./app/${TEST_WASM_BZIP2_APP_NAME}#run-browser`);
    const modal = page.getByTestId("run-modal-container");
    const input = modal.getByTestId("run-browser-file").filter({ hasText: "bzip2.txt", hasNotText: ".bz2" });
    const compressed = modal.getByTestId("run-browser-file").filter({ hasText: "bzip2.txt.bz2" });
    await expect(input).toBeVisible();

    await modal.getByTestId("run-browser-start").click();
    await expect(modal.getByTestId("run-browser-output")).toContainText("Exit code 0", { timeout: 30000 });
    await expect(compressed).toBeVisible();

    await input.getByTestId("run-browser-file-remove").click();
    await expect(input).toHaveCount(0);
    await modal.getByTestId("run-browser-args").fill("-d bzip2.txt.bz2");
    await modal.getByTestId("run-browser-start").click();
    await expect(modal.getByTestId("run-browser-output")).toContainText("Exit code 0", { timeout: 30000 });
    await expect(input).toBeVisible();
  });
  // The WASI build of `cpdf` replaces the C code of zlib, AES and SHA-2 with OCaml code.
  test("runs the WASI program that stamps and encrypts a PDF", async ({ page }) => {
    // eslint-disable-next-line playwright/no-skipped-test
    test.skip(TEST_WASM_CPDF_APP_NAME === "", "No app with cpdf");
    await page.goto(`./app/${TEST_WASM_CPDF_APP_NAME}#run-browser`);
    const modal = page.getByTestId("run-modal-container");
    const output = modal.getByTestId("run-browser-output");
    await expect(modal.getByTestId("run-browser-file").filter({ hasText: "sample.pdf" })).toBeVisible();

    await modal.getByTestId("run-browser-start").click();
    await expect(output).toContainText("Exit code 0", { timeout: 30000 });
    await expect(modal.getByTestId("run-browser-file").filter({ hasText: "stamped.pdf" })).toBeVisible();

    await modal.getByTestId("run-browser-args").fill("-encrypt AES256 owner user stamped.pdf -o secret.pdf");
    await modal.getByTestId("run-browser-start").click();
    await expect(output).toContainText("Exit code 0", { timeout: 30000 });

    await modal.getByTestId("run-browser-args").fill("-info secret.pdf user=user");
    await modal.getByTestId("run-browser-start").click();
    await expect(output).toContainText("Exit code 0", { timeout: 30000 });
    await expect(output).toContainText("Encryption: 256bit AES");
  });
});
