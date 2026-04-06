const getPreferences = () => {
  const preferences_install = localStorage.getItem("preferences_install");

  let preferences_theme = localStorage.getItem("preferences_theme");
  if (!preferences_theme) {
    const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    preferences_theme = isDark ? "dark" : "light";
  }
  document.documentElement.setAttribute("data-bs-theme", preferences_theme);

  return { theme: preferences_theme, install: preferences_install };
};

const initPreferences = (app) => {
  app.ports.savePreferencesThemeString.subscribe((theme) => {
    localStorage.setItem("preferences_theme", theme);
    document.documentElement.setAttribute("data-bs-theme", theme);
  });
  app.ports.savePreferencesInstallString.subscribe((preferences_install) => {
    localStorage.setItem("preferences_install", preferences_install);
  });
};

export { getPreferences, initPreferences };
