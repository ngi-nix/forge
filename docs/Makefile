SPHINXOPTS    = -W
SPHINXBUILD   = sphinx-build
BUILDDIR      = build

ALLSPHINXOPTS = -d $(BUILDDIR)/doctrees $(SPHINXOPTS) .

.PHONY: help clean html linkcheck

help:
	@echo "Usage: make <target>"
	@echo "  html       Build HTML documentation"
	@echo "  linkcheck  Check all external links"
	@echo "  clean      Remove build output"

clean:
	rm -rf $(BUILDDIR)/*

html:
	$(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(BUILDDIR)/html
	@echo "Build finished. HTML pages are in $(BUILDDIR)/html."

linkcheck:
	$(SPHINXBUILD) -b linkcheck $(ALLSPHINXOPTS) $(BUILDDIR)/linkcheck
