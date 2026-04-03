const initSmoothScrollPort = (app) => {
  app.ports.scrollToAndHighlight.subscribe((id) => {
    requestAnimationFrame(() => {
      let element = document.getElementById(id);
      if (element) {
        element.scrollIntoView({ behavior: "smooth", block: "start" });
        element.classList.add("trigger-pulse");
        setTimeout(() => {
          element.classList.remove("trigger-pulse");
        }, 2000);
      }
    });
  });
};

export { initSmoothScrollPort };
