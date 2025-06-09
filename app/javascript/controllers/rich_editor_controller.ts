import { BaseController } from "./base/BaseController";

interface Command {
  command: string;
  value?: string | null;
}

export default class extends BaseController {
  static targets = ["editor", "hiddenInput", "toolbar", "expandButton", "container"];
  
  declare readonly hasEditorTarget: boolean;
  declare readonly hasHiddenInputTarget: boolean;
  declare readonly hasToolbarTarget: boolean;
  declare readonly hasExpandButtonTarget: boolean;
  declare readonly hasContainerTarget: boolean;
  declare readonly editorTarget: HTMLDivElement;
  declare readonly hiddenInputTarget: HTMLInputElement;
  declare readonly toolbarTarget: HTMLElement;
  declare readonly expandButtonTarget: HTMLButtonElement;
  declare readonly containerTarget: HTMLElement;

  private isExpanded: boolean = false;

  connect(): void {
    if (!this.hasEditorTarget || !this.hasHiddenInputTarget) {
      this.showError('Rich editor targets not found');
      return;
    }

    this.setupToolbar();
    this.setupEditor();
    this.setupExpandButton();
  }

  private setupToolbar(): void {
    if (!this.hasToolbarTarget) return;

    const buttons = this.toolbarTarget.querySelectorAll('.rich-editor-button');
    buttons.forEach((button) => {
      this.addManagedEventListener(button, 'click', (e) => {
        e.preventDefault();
        const cmd = button.getAttribute('data-command');
        const value = button.getAttribute('data-value');
        if (cmd) {
          this.executeCommand({ command: cmd, value });
        }
      });
    });
  }

  private setupEditor(): void {
    this.addManagedEventListener(this.editorTarget, 'input', () => this.updateHiddenInput());
    this.addManagedEventListener(this.editorTarget, 'keyup', () => this.updateButtonStates());
    this.addManagedEventListener(this.editorTarget, 'mouseup', () => this.updateButtonStates());
    
    // Set initial focus
    setTimeout(() => this.editorTarget.focus(), 100);
  }

  private setupExpandButton(): void {
    if (!this.hasExpandButtonTarget || !this.hasContainerTarget) return;
    
    this.addManagedEventListener(this.expandButtonTarget, 'click', () => this.toggleExpand());
  }

  private executeCommand(cmd: Command): void {
    if (cmd.command === 'createLink') {
      const url = prompt('Enter the link URL:');
      if (url) {
        document.execCommand(cmd.command, false, url);
      }
    } else if (cmd.command === 'formatBlock' && cmd.value) {
      document.execCommand(cmd.command, false, cmd.value);
    } else if (cmd.command === 'toggleCode') {
      this.toggleCode();
    } else {
      document.execCommand(cmd.command, false, cmd.value || '');
    }
    
    this.updateButtonStates();
    this.updateHiddenInput();
    this.editorTarget.focus();
  }

  private updateHiddenInput(): void {
    if (this.hasHiddenInputTarget && this.hasEditorTarget) {
      this.hiddenInputTarget.value = this.editorTarget.innerHTML;
    }
  }

  private updateButtonStates(): void {
    if (!this.hasToolbarTarget) return;

    const buttons = this.toolbarTarget.querySelectorAll('.rich-editor-button');
    buttons.forEach((button) => {
      const command = button.getAttribute('data-command');
      if (!command) return;

      if (command === 'formatBlock') {
        const value = button.getAttribute('data-value');
        const formatBlock = document.queryCommandValue('formatBlock');
        button.classList.toggle('active', formatBlock.toLowerCase() === value);
      } else if (command === 'toggleCode') {
        const isCode = this.isInsideCode();
        button.classList.toggle('active', isCode);
      } else {
        try {
          button.classList.toggle('active', document.queryCommandState(command));
        } catch (e) {
          // Some commands might not support queryCommandState
        }
      }
    });
  }

  private isInsideCode(): boolean {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return false;
    
    let node: Node | null = selection.anchorNode;
    while (node && node !== this.editorTarget) {
      if (node.nodeName === 'CODE') return true;
      node = node.parentNode;
    }
    return false;
  }

  private toggleCode(): void {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return;
    
    const range = selection.getRangeAt(0);
    let node: Node | null = selection.anchorNode;
    
    // Check if we're inside a code element
    while (node && node !== this.editorTarget) {
      if (node.nodeName === 'CODE') {
        // Remove code formatting
        const text = document.createTextNode(node.textContent || '');
        node.parentNode?.replaceChild(text, node);
        range.selectNodeContents(text);
        selection.removeAllRanges();
        selection.addRange(range);
        return;
      }
      node = node.parentNode;
    }
    
    // Apply code formatting
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

  private toggleExpand(): void {
    this.isExpanded = !this.isExpanded;
    this.containerTarget.classList.toggle('expanded', this.isExpanded);
    
    const expandIcon = this.isExpanded ? 
      `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 16 16" aria-hidden="true" fill="currentColor"><path d="M10.75 1a.75.75 0 0 1 .75.75v2.5c0 .138.112.25.25.25h2.5a.75.75 0 0 1 0 1.5h-2.5A1.75 1.75 0 0 1 10 4.25v-2.5a.75.75 0 0 1 .75-.75Zm-5.5 0a.75.75 0 0 1 .75.75v2.5A1.75 1.75 0 0 1 4.25 6h-2.5a.75.75 0 0 1 0-1.5h2.5a.25.25 0 0 0 .25-.25v-2.5A.75.75 0 0 1 5.25 1ZM1 10.75a.75.75 0 0 1 .75-.75h2.5c.966 0 1.75.784 1.75 1.75v2.5a.75.75 0 0 1-1.5 0v-2.5a.25.25 0 0 0-.25-.25h-2.5a.75.75 0 0 1-.75-.75Zm9 1c0-.966.784-1.75 1.75-1.75h2.5a.75.75 0 0 1 0 1.5h-2.5a.25.25 0 0 0-.25.25v2.5a.75.75 0 0 1-1.5 0Z"/></svg>` :
      `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 16 16" aria-hidden="true" fill="currentColor"><path d="M1.75 10a.75.75 0 0 1 .75.75v2.5c0 .138.112.25.25.25h2.5a.75.75 0 0 1 0 1.5h-2.5A1.75 1.75 0 0 1 1 13.25v-2.5a.75.75 0 0 1 .75-.75Zm12.5 0a.75.75 0 0 1 .75.75v2.5A1.75 1.75 0 0 1 13.25 15h-2.5a.75.75 0 0 1 0-1.5h2.5a.25.25 0 0 0 .25-.25v-2.5a.75.75 0 0 1 .75-.75ZM2.75 2.5a.25.25 0 0 0-.25.25v2.5a.75.75 0 0 1-1.5 0v-2.5C1 1.784 1.784 1 2.75 1h2.5a.75.75 0 0 1 0 1.5ZM10 1.75a.75.75 0 0 1 .75-.75h2.5c.966 0 1.75.784 1.75 1.75v2.5a.75.75 0 0 1-1.5 0v-2.5a.25.25 0 0 0-.25-.25h-2.5a.75.75 0 0 1-.75-.75Z"/></svg>`;
    
    this.expandButtonTarget.innerHTML = expandIcon;
    this.expandButtonTarget.title = this.isExpanded ? "Collapse editor" : "Expand editor";
  }
}
