import { init as initNavigation } from "./Navigation.js";
import { initClipboard } from "./Clipboard.js";
import { getPreferences, initPreferences } from "./Preferences.js";
import { initSmoothScroll } from "./SmoothScroll.js";

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

const app = Elm.Main.init({
  node: document.getElementById("elm-main"),
  flags: {
    href: window.location.href,
    flags_preferences: getPreferences(),
  },
});

initClipboard(app);
initNavigation({
  navCmd: app.ports.navCmd,
  onNavEvent: app.ports.onNavEvent,
});
initPreferences(app);
initSmoothScroll(app);
