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

// Show native tooltip only if description is truncated by ellipses
// Use MutationObserver so the title is present *before* hover, ensuring native tooltips display instantly
const updateTruncatedTitles = () => {
  document.querySelectorAll(".m-item-card-description").forEach(desc => {
    // If the content is larger than the clamped box, it has ellipses
    if (desc.scrollHeight > desc.clientHeight) {
      if (!desc.hasAttribute("title")) {
        desc.setAttribute("title", desc.getAttribute("data-full-text") || desc.textContent);
      }
    } else {
      desc.removeAttribute("title");
    }
  });
};

const observer = new MutationObserver(() => {
  // debounce slightly to let Elm finish DOM updates and browser layout
  requestAnimationFrame(updateTruncatedTitles);
});
observer.observe(document.body, { childList: true, subtree: true, characterData: true });
window.addEventListener("resize", updateTruncatedTitles);
// Run once on load
setTimeout(updateTruncatedTitles, 100);

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
