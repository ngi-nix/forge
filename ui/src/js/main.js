import { init as initNavigationPort } from "./Navigation.js";
import { getInitialTheme, initThemePort } from "./ThemeSwitch.js";
import { initClipboardListener } from "./Clipboard.js";
import {
  getInitialFlakePreference,
  initFlakePreferencePort,
} from "./FlakePreference.js";
import { initSmoothScrollPort } from "./SmoothScroll.js";

const startingFlakePreference = getInitialFlakePreference();
const startingTheme = getInitialTheme();

// work around github pages adding extra trailing slash
if (
  window.location.pathname.endsWith("/") &&
  window.location.pathname !== "/"
) {
  const cleanUrl =
    window.location.pathname.slice(0, -1) +
    window.location.search +
    window.location.hash;
  window.history.replaceState(null, "", cleanUrl);
}

// init state
const app = Elm.Main.init({
  node: document.getElementById("elm-main"),
  flags: {
    href: window.location.href,
    theme: startingTheme,
    prefersFlakes: startingFlakePreference,
  },
});

// register ports

initClipboardListener(app);

initNavigationPort({
  navCmd: app.ports.navCmd,
  onNavEvent: app.ports.onNavEvent,
});

initFlakePreferencePort(app);

initSmoothScrollPort(app);

initThemePort(app);
