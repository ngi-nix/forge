# URL with a scheme.
{ lib }:
# https://www.rfc-editor.org/rfc/rfc3986#section-3.1
lib.types.strMatching "[a-zA-Z][a-zA-Z0-9+\-.]*://[^ \t\n]+"
