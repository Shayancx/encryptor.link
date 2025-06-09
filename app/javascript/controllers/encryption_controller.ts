import { BaseController } from "./base/BaseController";
import CryptographyService from "../services/CryptographyService";
import ValidationService from "../services/ValidationService";
import ErrorService from "../services/ErrorService";
import { ProgressCallback } from "../types/crypto.types";
import QRCode from "qrcode";

interface FileItem {
  file: File;
  id: string;
}

export default class extends BaseController {
  static targets = [
    "form", "passwordToggle", "passwordInput", "passwordContainer",
    "messageInput", "ttlSelect", "viewsSelect", "burnToggle", "fileInput",
    "dropArea", "filesContainer", "filesListBody", "encryptButton",
    "encryptButtonText", "progressDots", "encryptedLink", "copyButton",
    "resultContainer", "resultMessage", "qrToggle", "qrContainer",
    "qrTab", "qrPanel", "resultTabs"
  ];

  // Declare all targets
  declare readonly hasFormTarget: boolean;
  declare readonly hasPasswordToggleTarget: boolean;
  declare readonly hasPasswordInputTarget: boolean;
  declare readonly hasPasswordContainerTarget: boolean;
  declare readonly hasMessageInputTarget: boolean;
  declare readonly hasTtlSelectTarget: boolean;
  declare readonly hasViewsSelectTarget: boolean;
  declare readonly hasBurnToggleTarget: boolean;
  declare readonly hasFileInputTarget: boolean;
  declare readonly hasDropAreaTarget: boolean;
  declare readonly hasFilesContainerTarget: boolean;
  declare readonly hasFilesListBodyTarget: boolean;
  declare readonly hasEncryptButtonTarget: boolean;
  declare readonly hasEncryptButtonTextTarget: boolean;
  declare readonly hasProgressDotsTarget: boolean;
  declare readonly hasEncryptedLinkTarget: boolean;
  declare readonly hasCopyButtonTarget: boolean;
  declare readonly hasResultContainerTarget: boolean;
  declare readonly hasResultMessageTarget: boolean;
  declare readonly hasQrToggleTarget: boolean;
  declare readonly hasQrContainerTarget: boolean;
  declare readonly hasQrTabTarget: boolean;
  declare readonly hasQrPanelTarget: boolean;
  declare readonly hasResultTabsTarget: boolean;

  declare readonly formTarget: HTMLFormElement;
  declare readonly passwordToggleTarget: HTMLInputElement;
  declare readonly passwordInputTarget: HTMLInputElement;
  declare readonly passwordContainerTarget: HTMLElement;
  declare readonly messageInputTarget: HTMLInputElement;
  declare readonly ttlSelectTarget: HTMLSelectElement;
  declare readonly viewsSelectTarget: HTMLSelectElement;
  declare readonly burnToggleTarget: HTMLInputElement;
  declare readonly fileInputTarget: HTMLInputElement;
  declare readonly dropAreaTarget: HTMLElement;
  declare readonly filesContainerTarget: HTMLElement;
  declare readonly filesListBodyTarget: HTMLElement;
  declare readonly encryptButtonTarget: HTMLButtonElement;
  declare readonly encryptButtonTextTarget: HTMLElement;
  declare readonly progressDotsTarget: HTMLElement;
  declare readonly encryptedLinkTarget: HTMLInputElement;
  declare readonly copyButtonTarget: HTMLButtonElement;
  declare readonly resultContainerTarget: HTMLElement;
  declare readonly resultMessageTarget: HTMLElement;
  declare readonly qrToggleTarget: HTMLInputElement;
  declare readonly qrContainerTarget: HTMLElement;
  declare readonly qrTabTarget: HTMLElement;
  declare readonly qrPanelTarget: HTMLElement;
  declare readonly resultTabsTarget: HTMLElement;

  private selectedFiles: FileItem[] = [];
  private isEncrypting: boolean = false;

  connect(): void {
    this.setupFileHandling();
    this.setupPasswordToggle();
    this.setupBurnAfterReading();
  }

  private setupFileHandling(): void {
    if (this.hasFileInputTarget) {
      this.addManagedEventListener(this.fileInputTarget, 'change', (e) => {
        const target = e.target as HTMLInputElement;
        if (target.files) {
          this.handleFiles(target.files);
        }
      });
    }

    if (this.hasDropAreaTarget) {
      this.addManagedEventListener(this.dropAreaTarget, 'click', () => {
        if (this.hasFileInputTarget) {
          this.fileInputTarget.click();
        }
      });

      this.addManagedEventListener(this.dropAreaTarget, 'dragover', (e) => {
        e.preventDefault();
        this.dropAreaTarget.classList.add('dragover');
      });

      this.addManagedEventListener(this.dropAreaTarget, 'dragleave', () => {
        this.dropAreaTarget.classList.remove('dragover');
      });

      this.addManagedEventListener(this.dropAreaTarget, 'drop', (e) => {
        e.preventDefault();
        this.dropAreaTarget.classList.remove('dragover');
        const dt = (e as DragEvent).dataTransfer;
        if (dt?.files) {
          this.handleFiles(dt.files);
        }
      });
    }
  }

  private setupPasswordToggle(): void {
    if (!this.hasPasswordToggleTarget || !this.hasPasswordContainerTarget) return;

    // Set initial state
    this.passwordContainerTarget.style.display = this.passwordToggleTarget.checked ? 'block' : 'none';

    this.addManagedEventListener(this.passwordToggleTarget, 'change', () => {
      const isChecked = this.passwordToggleTarget.checked;
      this.passwordContainerTarget.style.display = isChecked ? 'block' : 'none';
      
      if (!isChecked && this.hasPasswordInputTarget) {
        this.passwordInputTarget.value = '';
      }
    });
  }

  private setupBurnAfterReading(): void {
    if (!this.hasBurnToggleTarget) return;

    this.addManagedEventListener(this.burnToggleTarget, 'change', () => {
      if (this.hasViewsSelectTarget) {
        this.viewsSelectTarget.disabled = this.burnToggleTarget.checked;
        if (this.burnToggleTarget.checked) {
          this.viewsSelectTarget.value = '1';
        }
      }

      const burnWarning = document.getElementById('burnWarning');
      if (burnWarning) {
        burnWarning.classList.toggle('d-none', !this.burnToggleTarget.checked);
      }
    });
  }

  private handleFiles(files: FileList): void {
    Array.from(files).forEach(file => {
      this.selectedFiles.push({
        file,
        id: Math.random().toString(36).substr(2, 9)
      });
    });
    this.renderFiles();
  }

  private renderFiles(): void {
    if (!this.hasFilesContainerTarget || !this.hasFilesListBodyTarget) return;

    this.filesListBodyTarget.innerHTML = '';
    let totalSize = 0;

    this.selectedFiles.forEach((fileItem, index) => {
      totalSize += fileItem.file.size;

      const item = document.createElement('div');
      item.className = 'gh-file-item';
      item.innerHTML = `
        <div class="file-info">
          <span class="file-name">${this.escapeHtml(fileItem.file.name)}</span>
          <span class="file-size">(${(fileItem.file.size / 1024 / 1024).toFixed(2)} MB)</span>
        </div>
      `;

      const removeBtn = document.createElement('button');
      removeBtn.type = 'button';
      removeBtn.className = 'btn btn-sm btn-outline-danger ms-2';
      removeBtn.textContent = 'Remove';
      this.addManagedEventListener(removeBtn, 'click', () => {
        this.selectedFiles.splice(index, 1);
        this.renderFiles();
      });

      item.appendChild(removeBtn);
      this.filesListBodyTarget.appendChild(item);
    });

    // Update total size display
    const totalSizeElement = document.getElementById('totalSize');
    if (totalSizeElement) {
      totalSizeElement.textContent = `Total: ${(totalSize / 1024 / 1024).toFixed(2)} MB`;
    }

    this.filesContainerTarget.style.display = this.selectedFiles.length > 0 ? '' : 'none';
  }

  async encrypt(event: Event): Promise<void> {
    event.preventDefault();

    if (this.isEncrypting) return;

    try {
      this.isEncrypting = true;
      
      // Get form values with null safety
      const message = this.getRichEditorContent();
      const ttl = this.hasTtlSelectTarget ? parseInt(this.ttlSelectTarget.value, 10) : 86400;
      const views = this.hasViewsSelectTarget ? parseInt(this.viewsSelectTarget.value, 10) : 1;
      const burnAfterReading = this.hasBurnToggleTarget ? this.burnToggleTarget.checked : false;
      const usePassword = this.hasPasswordToggleTarget ? this.passwordToggleTarget.checked : false;
      const password = usePassword && this.hasPasswordInputTarget ? this.passwordInputTarget.value : '';
      const files = this.selectedFiles.map(item => item.file);

      // Validate input
      const validationError = ValidationService.validate({ message, files, ttl, views });
      if (validationError) {
        ErrorService.handle(validationError);
        return;
      }

      // Validate password if used
      if (usePassword && password) {
        const passwordError = ValidationService.validatePassword(password);
        if (passwordError) {
          ErrorService.handle(passwordError);
          return;
        }
      }

      // Check if encryption functions are available
      if (typeof CryptographyService.encryptMessage !== 'function' ||
          typeof CryptographyService.encryptFiles !== 'function') {
        ErrorService.handle(new Error('Encryption module failed to load. Please refresh the page.'));
        return;
      }

      // Update UI for encryption progress
      this.setEncryptionUI(true);

      // Create progress callback
      const progressCallback: ProgressCallback = (progress) => {
        if (!this.hasEncryptButtonTextTarget) return;
        
        let text = progress.status;
        if (progress.details) text += ` ${progress.details}`;
        if (progress.percentage !== undefined) text += ` (${progress.percentage}%)`;
        if (progress.speed !== undefined) text += ` ${progress.speed.toFixed(2)} MB/s`;
        if (progress.eta !== undefined) text += ` ETA: ${progress.eta.toFixed(1)}s`;
        
        this.encryptButtonTextTarget.textContent = text;
      };

      // Perform encryption
      let link: string;
      if (files.length > 0) {
        link = await CryptographyService.encryptFiles(
          files,
          message,
          ttl,
          views,
          password,
          burnAfterReading,
          progressCallback
        );
      } else {
        progressCallback({ percentage: 50, status: 'Encrypting message...' });
        link = await CryptographyService.encryptMessage(message, ttl, views, password, burnAfterReading);
        progressCallback({ percentage: 100, status: 'Complete!' });
      }

      // Show results
      this.showResults(link, usePassword);
      
      // Reset form
      this.resetForm();

    } catch (error) {
      ErrorService.handle(error as Error);
    } finally {
      this.isEncrypting = false;
      this.setEncryptionUI(false);
    }
  }

  private getRichEditorContent(): string {
    const richEditor = document.getElementById('richEditor');
    const hiddenInput = document.getElementById('hidden_message') as HTMLInputElement;
    
    if (richEditor) {
      return richEditor.innerHTML;
    } else if (hiddenInput) {
      return hiddenInput.value;
    } else if (this.hasMessageInputTarget) {
      return this.messageInputTarget.value;
    }
    
    return '';
  }

  private setEncryptionUI(encrypting: boolean): void {
    if (this.hasEncryptButtonTarget) {
      this.encryptButtonTarget.classList.toggle('loading', encrypting);
      this.encryptButtonTarget.classList.toggle('btn-progress', encrypting);
      this.encryptButtonTarget.disabled = encrypting;
    }

    if (this.hasProgressDotsTarget) {
      this.progressDotsTarget.classList.toggle('d-none', !encrypting);
    }

    if (!encrypting && this.hasEncryptButtonTextTarget) {
      this.encryptButtonTextTarget.textContent = 'Encrypt & Generate Link';
    }
  }

  private showResults(link: string, usePassword: boolean): void {
    if (this.hasEncryptedLinkTarget) {
      this.encryptedLinkTarget.value = link;
    }

    // Handle QR code generation
    if (this.hasQrToggleTarget && this.qrToggleTarget.checked) {
      this.generateQRCode(link);
    }

    if (this.hasResultContainerTarget) {
      this.resultContainerTarget.classList.remove('d-none');
    }

    if (this.hasResultMessageTarget) {
      if (usePassword) {
        this.resultMessageTarget.textContent = 'This link requires a password to access. Share both the link and password separately for maximum security.';
      } else {
        this.resultMessageTarget.textContent = 'This link contains the decryption key. Anyone with this link can view your message or download your files.';
      }
    }

    // Scroll to results
    if (this.hasResultContainerTarget) {
      this.resultContainerTarget.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }

  private async generateQRCode(link: string): Promise<void> {
    if (!this.hasQrContainerTarget) return;

    // Show QR tab and panel
    if (this.hasQrTabTarget) {
      this.qrTabTarget.style.display = '';
    }
    if (this.hasQrPanelTarget) {
      this.qrPanelTarget.style.display = '';
    }
    if (this.hasResultTabsTarget) {
      this.resultTabsTarget.style.display = '';
    }

    // Clear existing QR code
    this.qrContainerTarget.innerHTML = '';

    const canvas = document.createElement('canvas');
    await QRCode.toCanvas(canvas, link, {
      width: 256,
      color: {
        dark: '#000000',
        light: '#ffffff'
      },
      errorCorrectionLevel: 'H'
    });
    this.qrContainerTarget.appendChild(canvas);
  }

  private resetForm(): void {
    if (this.hasFormTarget) {
      this.formTarget.reset();
    }

    // Clear rich editor
    const richEditor = document.getElementById('richEditor');
    if (richEditor) {
      richEditor.innerHTML = '';
    }

    // Clear hidden message input
    const hiddenInput = document.getElementById('hidden_message') as HTMLInputElement;
    if (hiddenInput) {
      hiddenInput.value = '';
    }

    // Clear message input
    if (this.hasMessageInputTarget) {
      this.messageInputTarget.value = '';
    }

    // Clear selected files
    this.selectedFiles = [];
    this.renderFiles();

    // Reset password toggle
    if (this.hasPasswordToggleTarget && this.hasPasswordContainerTarget) {
      this.passwordToggleTarget.checked = false;
      this.passwordContainerTarget.style.display = 'none';
      if (this.hasPasswordInputTarget) {
        this.passwordInputTarget.value = '';
      }
    }
  }

  copy(): void {
    if (!this.hasEncryptedLinkTarget || !this.hasCopyButtonTarget) return;

    try {
      this.encryptedLinkTarget.select();
      document.execCommand('copy');

      const originalHTML = this.copyButtonTarget.innerHTML;
      this.copyButtonTarget.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1"><path d="M20 6 9 17l-5-5"/></svg> Copied!';
      this.copyButtonTarget.classList.add('btn-success', 'copied');
      this.copyButtonTarget.classList.remove('btn-outline-primary');

      setTimeout(() => {
        this.copyButtonTarget.innerHTML = originalHTML;
        this.copyButtonTarget.classList.remove('btn-success', 'copied');
        this.copyButtonTarget.classList.add('btn-outline-primary');
      }, 2000);
    } catch (error) {
      ErrorService.handle(new Error('Failed to copy to clipboard'));
    }
  }

  private escapeHtml(text: string): string {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  protected validateState(): boolean {
    return this.hasFormTarget && 
           this.hasEncryptButtonTarget && 
           (this.hasMessageInputTarget || !!document.getElementById('richEditor'));
  }
}
