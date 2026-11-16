export const BASE_URL = process.env.BASE_URL || "http://127.0.0.1:3000";
const isProd = BASE_URL.includes("ngi.nixos.org")
  || BASE_URL.includes("github.io")
  || process.env.UI_CMD == "forge-ui";

export const TEST_APP_NAME = process.env.TEST_APP_NAME || (isProd ? "emerge" : "mock-test");
// An app with `programs.runtimes.browser.wasmPackage`. The mock config has none.
export const TEST_WASM_APP_NAME = process.env.TEST_WASM_APP_NAME || (isProd ? "jaq" : "");
// An app with `programs.runtimes.browser.files`, whose example writes `sample.pdf`.
export const TEST_WASM_FILES_APP_NAME = process.env.TEST_WASM_FILES_APP_NAME || (isProd ? "typst" : "");
// An app with `bzip2`, whose example compresses `bzip2.txt`.
export const TEST_WASM_BZIP2_APP_NAME = process.env.TEST_WASM_BZIP2_APP_NAME || (isProd ? "libbzip2-rs" : "");
// An app with `cpdf`, whose example adds text to `sample.pdf`.
export const TEST_WASM_CPDF_APP_NAME = process.env.TEST_WASM_CPDF_APP_NAME || (isProd ? "cpdf" : "");
export const TEST_PKG_NAME = process.env.TEST_PKG_NAME || (isProd ? "emerge" : "mock-test-pkg");
export const TEST_APP_SEARCH = process.env.TEST_APP_SEARCH || (isProd ? "emerge" : "mock-test");
export const TEST_PKG_SEARCH = process.env.TEST_PKG_SEARCH || (isProd ? "emerge" : "mock-test");

export const TEST_RECIPE_OPTION = process.env.TEST_RECIPE_OPTION || "apps.<name>.description";
