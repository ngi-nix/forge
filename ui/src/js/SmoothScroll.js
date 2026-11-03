const initSmoothScroll = (app) => {
  if (app.ports.scrollToAndHighlight) {
    app.ports.scrollToAndHighlight.subscribe((id) => {
      requestAnimationFrame(() => {
        let element = document.getElementById(id);
        if (element) {
          element.scrollIntoView({ behavior: "smooth", block: "center" });
          element.classList.add("trigger-pulse");
          setTimeout(() => {
            element.classList.remove("trigger-pulse");
          }, 2000);
        }
      });
    });
  }

  if (app.ports.scrollIntoView) {
    app.ports.scrollIntoView.subscribe((id) => {
      requestAnimationFrame(() => {
        let element = document.getElementById(id);
        if (element) {
          element.scrollIntoView({ behavior: "auto", block: "nearest" });
        }
      });
    });
  }
};

export { initSmoothScroll };
