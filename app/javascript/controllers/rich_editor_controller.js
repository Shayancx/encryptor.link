import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["editor", "hiddenInput", "toolbar", "expandButton", "container"];

  connect() {
    if (this.hasEditorTarget && this.hasHiddenInputTarget) {
      const buttons = this.toolbarTarget.querySelectorAll('.rich-editor-button');
      buttons.forEach(button => {
        button.addEventListener('click', (e) => {
          e.preventDefault();
          const command = button.getAttribute('data-command');
          const value = button.getAttribute('data-value') || null;
          if (command === 'createLink') {
            const url = prompt('Enter the link URL:');
            if (url) { document.execCommand(command, false, url); }
          } else if (command === 'formatBlock') {
            document.execCommand(command, false, value);
          } else if (command === 'toggleCode') {
            this.toggleCode();
          } else {
            document.execCommand(command, false, null);
          }
          this.updateButtonStates();
          this.updateHiddenInput();
          this.editorTarget.focus();
        });
      });

      this.editorTarget.addEventListener('input', () => this.updateHiddenInput());
      this.editorTarget.addEventListener('keyup', () => this.updateButtonStates());
      this.editorTarget.addEventListener('mouseup', () => this.updateButtonStates());
      setTimeout(() => this.editorTarget.focus(), 100);
    }
    if (this.hasExpandButtonTarget && this.hasContainerTarget) {
      this.expandButtonTarget.addEventListener('click', () => this.toggleExpand());
    }
  }

  updateHiddenInput() {
    if (this.hasHiddenInputTarget && this.hasEditorTarget) {
      this.hiddenInputTarget.value = this.editorTarget.innerHTML;
    }
  }

  updateButtonStates() {
    const buttons = this.toolbarTarget.querySelectorAll('.rich-editor-button');
    buttons.forEach(button => {
      const command = button.getAttribute('data-command');
      if (command === 'formatBlock') {
        const value = button.getAttribute('data-value');
        const formatBlock = document.queryCommandValue('formatBlock');
        button.classList.toggle('active', formatBlock.toLowerCase() === value);
      } else if (command === 'toggleCode') {
        let node = document.getSelection().anchorNode;
        let isCode = false;
        while (node && node !== this.editorTarget) {
          if (node.nodeName === 'CODE') { isCode = true; break; }
          node = node.parentNode;
        }
        button.classList.toggle('active', isCode);
      } else {
        button.classList.toggle('active', document.queryCommandState(command));
      }
    });
  }

  toggleCode() {
    const selection = window.getSelection();
    if (!selection.rangeCount) return;
    const range = selection.getRangeAt(0);
    let node = selection.anchorNode;
    while (node && node !== this.editorTarget) {
      if (node.nodeName === 'CODE') {
        const text = document.createTextNode(node.textContent);
        node.parentNode.replaceChild(text, node);
        range.selectNodeContents(text);
        selection.removeAllRanges();
        selection.addRange(range);
        return;
      }
      node = node.parentNode;
    }
    if (range.collapsed) {
      const codeEl = document.createElement('code');
      range.insertNode(codeEl);
      selection.collapse(codeEl, 0);
    } else {
      const codeEl = document.createElement('code');
      codeEl.textContent = range.toString();
      range.deleteContents();
      range.insertNode(codeEl);
      selection.removeAllRanges();
      const newRange = document.createRange();
      newRange.selectNodeContents(codeEl);
      selection.addRange(newRange);
    }
  }

  toggleExpand() {
    this.containerTarget.classList.toggle('expanded');
    if (this.containerTarget.classList.contains('expanded')) {
      this.expandButtonTarget.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 16 16" aria-hidden="true" fill="currentColor"><path d="M10.75 1a.75.75 0 0 1 .75.75v2.5c0 .138.112.25.25.25h2.5a.75.75 0 0 1 0 1.5h-2.5A1.75 1.75 0 0 1 10 4.25v-2.5a.75.75 0 0 1 .75-.75Zm-5.5 0a.75.75 0 0 1 .75.75v2.5A1.75 1.75 0 0 1 4.25 6h-2.5a.75.75 0 0 1 0-1.5h2.5a.25.25 0 0 0 .25-.25v-2.5A.75.75 0 0 1 5.25 1ZM1 10.75a.75.75 0 0 1 .75-.75h2.5c.966 0 1.75.784 1.75 1.75v2.5a.75.75 0 0 1-1.5 0v-2.5a.25.25 0 0 0-.25-.25h-2.5a.75.75 0 0 1-.75-.75Zm9 1c0-.966.784-1.75 1.75-1.75h2.5a.75.75 0 0 1 0 1.5h-2.5a.25.25 0 0 0-.25.25v2.5a.75.75 0 0 1-1.5 0Z"/></svg>`;
      this.expandButtonTarget.title = "Collapse editor";
    } else {
      this.expandButtonTarget.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 16 16" aria-hidden="true" fill="currentColor"><path d="M1.75 10a.75.75 0 0 1 .75.75v2.5c0 .138.112.25.25.25h2.5a.75.75 0 0 1 0 1.5h-2.5A1.75 1.75 0 0 1 1 13.25v-2.5a.75.75 0 0 1 .75-.75Zm12.5 0a.75.75 0 0 1 .75.75v2.5A1.75 1.75 0 0 1 13.25 15h-2.5a.75.75 0 0 1 0-1.5h2.5a.25.25 0 0 0 .25-.25v-2.5a.75.75 0 0 1 .75-.75ZM2.75 2.5a.25.25 0 0 0-.25.25v2.5a.75.75 0 0 1-1.5 0v-2.5C1 1.784 1.784 1 2.75 1h2.5a.75.75 0 0 1 0 1.5ZM10 1.75a.75.75 0 0 1 .75-.75h2.5c.966 0 1.75.784 1.75 1.75v2.5a.75.75 0 0 1-1.5 0v-2.5a.25.25 0 0 0-.25-.25h-2.5a.75.75 0 0 1-.75-.75Z"/></svg>`;
      this.expandButtonTarget.title = "Expand editor";
    }
  }
}
