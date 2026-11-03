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
