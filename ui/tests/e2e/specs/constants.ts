export const BASE_URL = process.env.BASE_URL || "http://127.0.0.1:3000";
const isProd = BASE_URL.includes("ngi.nixos.org")
  || BASE_URL.includes("github.io")
  || process.env.UI_CMD == "forge-ui";

export const TEST_APP_NAME = process.env.TEST_APP_NAME || (isProd ? "emerge" : "mock-test");
export const TEST_PKG_NAME = process.env.TEST_PKG_NAME || (isProd ? "emerge" : "mock-test-pkg");
export const TEST_APP_SEARCH = process.env.TEST_APP_SEARCH || (isProd ? "emerge" : "mock-test");
export const TEST_PKG_SEARCH = process.env.TEST_PKG_SEARCH || (isProd ? "emerge" : "mock-test");

export const TEST_RECIPE_OPTION = process.env.TEST_RECIPE_OPTION || "apps.<name>.description";
