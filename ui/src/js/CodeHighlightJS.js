// TODO revert the commit which introduces this when highlight.js version with https://github.com/highlightjs/highlight.js/pull/4576
// is available
function ensureMarkdownComments() {
  if (typeof hljs !== "undefined" && hljs.getLanguage && hljs.getLanguage("markdown")) {
    const mdLang = hljs.getLanguage("markdown");
    if (!mdLang._hasHtmlComment && mdLang.rawDefinition && hljs.COMMENT) {
      const rawDef = mdLang.rawDefinition;
      hljs.registerLanguage("markdown", (inst) => {
        const def = rawDef(inst);
        def.contains.unshift(inst.COMMENT("<!--", "-->"));
        return def;
      });
      hljs.getLanguage("markdown")._hasHtmlComment = true;
    }
  }
}

customElements.define(
  "highlightjs-code",
  class extends HTMLElement {
    constructor() {
      super();
    }
    connectedCallback() {
      this.setTextContent();
    }
    attributeChangedCallback() {
      this.setTextContent();
    }
    static get observedAttributes() {
      return ["language", "body"];
    }

    setTextContent() {
      const lang = this.getAttribute("language") || "plaintext";
      const code = this.getAttribute("body") || "";
      if (lang === "markdown") {
        ensureMarkdownComments();
      }
      const validLang = (typeof hljs !== "undefined" && hljs.getLanguage && hljs.getLanguage(lang))
        ? lang
        : "plaintext";
      try {
        const hljsVal = hljs.highlight(code, { language: validLang });
        this.innerHTML = `
          <pre class="p-3 rounded border border-secondary"><code class="hljs language-${validLang}">${hljsVal.value}</code></pre>
        `;
      } catch (e) {
        console.error("Highlight error:", e);
        const pre = document.createElement("pre");
        pre.className = "p-3 rounded border border-secondary";
        const codeEl = document.createElement("code");
        codeEl.className = "hljs language-plaintext";
        codeEl.textContent = code;
        pre.appendChild(codeEl);
        this.replaceChildren(pre);
      }
    }
  },
);
