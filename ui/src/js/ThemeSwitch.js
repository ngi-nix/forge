const setThemeAttribute = (theme) => {
  if (theme === "auto") {
    const isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    document.documentElement.setAttribute(
      "data-bs-theme",
      isDark ? "dark" : "light",
    );
  } else {
    document.documentElement.setAttribute("data-bs-theme", theme);
  }
};

const getInitialTheme = () => {
  const storedTheme = localStorage.getItem("theme") || "auto";
  setThemeAttribute(storedTheme);
  return storedTheme;
};

const initThemePorts = (app) => {
  app.ports.saveTheme.subscribe((theme) => {
    localStorage.setItem("theme", theme);
    setThemeAttribute(theme);
  });

  window
    .matchMedia("(prefers-color-scheme: dark)")
    .addEventListener("change", () => {
      const currentTheme = localStorage.getItem("theme") || "auto";
      if (currentTheme === "auto") {
        setThemeAttribute("auto");
      }
    });
};

export { getInitialTheme, initThemePorts };
