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
      const hljsVal = hljs.highlight(code, { language: lang });
      this.innerHTML = `
        <pre class="p-3 rounded border border-secondary"><code class="hljs language-${lang}">${hljsVal.value}</code></pre>
      `;
    }
  },
);
