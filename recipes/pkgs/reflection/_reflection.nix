{
  lib,
  stdenv,
  fetchFromGitHub,
  wrapGAppsHook4,

  rustPlatform,
  pkg-config,
  meson,
  ninja,
  cargo,
  rustc,

  gtk4,
  gtksourceview5,
  libadwaita,
  libpanel,
  vte-gtk4,
  glib,
  openssl,
  libspelling,
  blueprint-compiler,
  desktop-file-utils,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "reflection";
  version = "0.4";

  src = fetchFromGitHub {
    owner = "p2panda";
    repo = "reflection";
    tag = finalAttrs.version;
    hash = "sha256-VPfYbMAyKv+2lWJ/TcQ7Em6kbutnJQIgbBTEqOnEDcc=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-3RR/YfJsq0eaRhaVVnocV5R1fbQ6YKsQ3QVZ1dc5HsI=";
  };

  PKG_CONFIG_PATH = "${openssl.dev}/lib/pkgconfig";

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    desktop-file-utils
    glib
    gtk4
    meson
    ninja
    pkg-config
    rustPlatform.cargoSetupHook
    cargo
    rustc
    wrapGAppsHook4
    blueprint-compiler
    libspelling
  ];

  buildInputs = [
    gtk4
    gtksourceview5
    libadwaita
    libpanel
    vte-gtk4
    libspelling
  ];

  meta = {
    description = "Collaborative, local-first GTK text editor";
    homepage = "https://github.com/p2panda/reflection";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "reflection";
    maintainers = with lib.maintainers; [ hougo ];
    teams = with lib.teams; [ ngi ];
  };
})
