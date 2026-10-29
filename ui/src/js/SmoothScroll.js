const initSmoothScroll = (app) => {
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
  app.ports.scrollRow.subscribe(({ id, direction }) => {
    let element = document.getElementById(id);
    if (element) {
      // `scrollBy` uses the `scroll-behavior` of the element.
      // Elm's `Browser.Dom.setViewportOf` sets `scrollTop` after `scrollLeft`,
      // which stops a smooth scroll before it starts.
      // A step of less than the full width keeps the item at the edge in view.
      element.scrollBy({ left: direction * element.clientWidth * 0.8 });
    }
  });
};

export { initSmoothScroll };
