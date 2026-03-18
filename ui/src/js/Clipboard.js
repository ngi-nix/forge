export const initClipboardListener = (app) =>
  app.ports.copyToClipboard.subscribe((text) => {
    navigator.clipboard
      .writeText(text)
      .then(() => {
        var button = document.activeElement;
        if (button) {
          button.classList.add("active");
          setTimeout(() => {
            button.classList.remove("active");
          }, 2000);
        }
      })
      .catch((err) => {
        console.error("Failed to copy to clipboard:", err);
      });
  });
