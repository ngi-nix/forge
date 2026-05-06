const initDefaultPreferences = () => {
  const preferencesString = localStorage.getItem("preferences");

  let preferences = preferencesString !== null ? JSON.parse(preferencesString) : {};

  if (preferences.theme === undefined) {
    const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    preferences.theme = isDark ? "dark" : "light";
    localStorage.setItem("preferences", JSON.stringify(preferences));
  }

  if (preferences.install === undefined) {
    preferences.install = "nix_flake";
    localStorage.setItem("preferences", JSON.stringify(preferences));
  }

  if (preferences.container === undefined) {
    preferences.container = "podman";
    localStorage.setItem("preferences", JSON.stringify(preferences));
  }

  // Set the inital theme on page load
  document.documentElement.setAttribute("data-bs-theme", preferences.theme);

  return preferences;
};

const getPreferences = () => {
  const preferences = initDefaultPreferences();
  return preferences;
};

const initPreferences = (app) => {
  // Hack: remove initally set background color to avoid white flash when page reloads
  document.body.classList.remove("initial-bg-color");

  initDefaultPreferences();

  app.ports.setPreferencesJson.subscribe((preferences) => {
    localStorage.setItem("preferences", JSON.stringify(preferences));
    document.documentElement.setAttribute("data-bs-theme", preferences.theme);
  });
};

export { getPreferences, initPreferences };
