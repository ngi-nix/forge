import { initClipboard } from "./Clipboard.js";
import { registerIconFallbackonError } from "./IconFallback.js";
import { initNavigation } from "./Navigation.js";
import { getPreferences, initPreferences } from "./Preferences.js";
import { initSmoothScroll } from "./SmoothScroll.js";
import { initTitle } from "./Title.js";
import "./CodeHighlightJS.js";

// Intercept clicks if the user is selecting text, preventing cards from navigating
document.addEventListener("click", (e) => {
  const selection = window.getSelection();
  if (selection && selection.toString().trim().length > 0) {
    e.stopPropagation();
  }
}, true);

// work around github pages adding extra trailing slash
if (
  window.location.pathname.endsWith("/")
  && window.location.pathname !== "/"
) {
  const cleanUrl = window.location.pathname.slice(0, -1)
    + window.location.search
    + window.location.hash;
  window.history.replaceState(null, "", cleanUrl);
}

// Website analytics integration
if (window.location.hostname === "ngi.nixos.org") {
  // See "Embed code" from <https://offen.ngi.nixos.org/auditorium/572729d2-deee-4601-8c40-6c85fe00ded3/>.
  const script = document.createElement("script");
  script.async = true;
  script.src = "https://offen.ngi.nixos.org/script.js";
  script.dataset.accountId = "572729d2-deee-4601-8c40-6c85fe00ded3";
  document.head.appendChild(script);
}

const getWeeklySeed = () => Math.floor(Date.now() / (1000 * 60 * 60 * 24 * 7));

const app = Elm.Main.init({
  node: document.getElementById("elm-main"),
  flags: {
    href: window.location.href,
    flags_preferences: getPreferences(),
    flags_weeklySeed: getWeeklySeed(),
  },
});

initClipboard(app);
initNavigation({
  navCmd: app.ports.navCmd,
  onNavEvent: app.ports.onNavEvent,
});
initPreferences(app);
initSmoothScroll(app);
initTitle(app);
registerIconFallbackonError();
