/*
 * Rationale for this icon fallback listener
 *
 * - It is useful to never show broken icons to the user for the Applicaitons.
 * - Historically, we had urls of the form `/forge/apps/collabora-desktop-app` with the `-app` suffix
 *   For these urls we have a redirect but the application icon will be missing when visited via the old URL.
 *   See https://github.com/ngi-nix/forge/issues/545
 *
 * Inital attempt was a simple fix `attribute "onerror" ("this.onerror = null; this.src = '" ++ defaultAppIconPath ++ "'")`
 * Which is not allowed by elm as it is converting `onerror` attribute to `data-onerror`
 * Thus a dedicated file which adds these listeners. Even though dom lifecycle is manage by Elm, this still works.
 */
export const registerIconFallbackonError = () => {
  document.addEventListener("error", function(event) {
    const target = event.target;
    if (target.tagName.toLowerCase() !== "img") return;

    if (
      target.classList.contains("item-header-icon")
      || target.classList.contains("item-card-icon")
    ) {
      if (target.getAttribute("data-fallback-applied")) return;
      target.src = "resources/apps/app-icon.svg";
      target.setAttribute("data-fallback-applied", "true");
    }
  }, true);
};
