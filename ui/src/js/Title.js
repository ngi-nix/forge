const initTitle = (app) => {
  app.ports.setTitle.subscribe((title) => {
    document.title = title;
  });
};

export { initTitle };
