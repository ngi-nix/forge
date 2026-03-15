import { init } from './Navigation.js';

var app = Elm.Main.init({
  node: document.getElementById("elm-main"),
  flags: location.href,
});
window.NavigationPort.init({
  navCmd: app.ports.navCmd,
  onNavEvent: app.ports.onNavEvent,
});

// Handle copy to clipboard
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
