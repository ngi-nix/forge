{
  writeShellApplication,
  _forge-ui,
  _forge-options,
  _forge-docs,
  highlight-js,
}:
(writeShellApplication {
  name = "forge-ui-dev";
  text = ''
    out=./ui/build
    mkdir -p $out/js $out/css
    ln -snvf ${_forge-ui.passthru.bootstrapCss} $out/bootstrap
    ln -snvf ${_forge-options} $out/forge-options.json
    ln -snvf ${_forge-docs} $out/docs
    ln -snvf ${highlight-js}/highlight.min.js $out/js/highlight.min.js
    ln -snvf ${highlight-js}/theme.css $out/css/highlightjs-theme.css
  '';
  passthru = {
    inherit highlight-js;
  };
})
