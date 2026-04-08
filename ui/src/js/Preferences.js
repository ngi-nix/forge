const getPreferences = () => {
  const preferencesString = localStorage.getItem("preferences");
  let preferences = preferencesString ? JSON.parse(preferencesString) : {};

  if (preferences === null) {
    preferences = {};
  }

  if (preferences.theme === undefined) {
    const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    preferences.theme = isDark ? "dark" : "light";
  }

  document.documentElement.setAttribute("data-bs-theme", preferences.theme);

  return preferences;
};

const initPreferences = (app) => {
  app.ports.setPreferencesJson.subscribe((preferences) => {
    localStorage.setItem("preferences", JSON.stringify(preferences));
    document.documentElement.setAttribute("data-bs-theme", preferences.theme);
  });
};

export { getPreferences, initPreferences };
