import { init as initNavigationPort } from "./Navigation.js";
import { getInitialTheme, initThemePorts } from "./ThemeSwitch.js";
import { initClipboardListener } from "./Clipboard.js";

const startingTheme = getInitialTheme();

const app = Elm.Main.init({
  node: document.getElementById("elm-main"),
  flags: {
    href: location.href,
    theme: startingTheme,
  },
});

initNavigationPort({
  navCmd: app.ports.navCmd,
  onNavEvent: app.ports.onNavEvent,
});

initThemePorts(app);

initClipboardListener(app);
