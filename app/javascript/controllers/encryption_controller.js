import { Controller } from "@hotwired/stimulus";
import CryptographyService from "../services/cryptography_service";
import ValidationService from "../services/validation_service";
import ErrorService from "../services/error_service";

export default class extends Controller {
  static targets = [
    "form",
    "passwordToggle",
    "passwordInput",
    "passwordContainer",
    "messageInput",
    "ttlSelect",
    "viewsSelect",
    "burnToggle",
    "fileInput",
    "dropArea",
    "filesContainer",
    "filesListBody",
    "encryptButton",
    "encryptButtonText",
    "progressDots",
    "encryptedLink",
    "copyButton",
    "resultContainer",
    "resultMessage",
    "qrToggle",
    "qrContainer",
    "qrTab",
    "qrPanel",
    "resultTabs"
  ];

  connect() {
    this.selectedFiles = [];
    if (this.hasFileInputTarget) {
      this.fileInputTarget.addEventListener('change', (e) => this.handleFiles(e.target.files));
    }
    if (this.hasDropAreaTarget) {
      this.dropAreaTarget.addEventListener('click', () => this.fileInputTarget.click());
      this.dropAreaTarget.addEventListener('dragover', (e) => { e.preventDefault(); this.dropAreaTarget.classList.add('dragover'); });
      this.dropAreaTarget.addEventListener('dragleave', () => this.dropAreaTarget.classList.remove('dragover'));
      this.dropAreaTarget.addEventListener('drop', (e) => { e.preventDefault(); this.dropAreaTarget.classList.remove('dragover'); this.handleFiles(e.dataTransfer.files); });
    }

    if (this.hasPasswordToggleTarget && this.hasPasswordContainerTarget) {
      this.passwordContainerTarget.style.display = this.passwordToggleTarget.checked ? 'block' : 'none';
      this.passwordToggleTarget.addEventListener('change', () => {
        this.passwordContainerTarget.style.display = this.passwordToggleTarget.checked ? 'block' : 'none';
        if (!this.passwordToggleTarget.checked) this.passwordInputTarget.value = '';
      });
    }
  }

  handleFiles(files) {
    for (const file of files) {
      this.selectedFiles.push(file);
    }
    this.renderFiles();
  }

  renderFiles() {
    if (!this.hasFilesContainerTarget) return;
    const body = this.filesListBodyTarget;
    body.innerHTML = '';
    this.selectedFiles.forEach((file, index) => {
      const item = document.createElement('div');
      item.className = 'gh-file-item';
      item.innerHTML = `${file.name} (${(file.size / 1024 / 1024).toFixed(2)} MB)`;
      const removeBtn = document.createElement('button');
      removeBtn.type = 'button';
      removeBtn.className = 'btn btn-sm btn-outline-danger ms-2';
      removeBtn.textContent = 'Remove';
      removeBtn.addEventListener('click', () => {
        this.selectedFiles.splice(index, 1);
        this.renderFiles();
      });
      item.appendChild(removeBtn);
      body.appendChild(item);
    });
    this.filesContainerTarget.style.display = this.selectedFiles.length ? '' : 'none';
  }

  async encrypt(event) {
    event.preventDefault();
    const message = this.hasMessageInputTarget ? this.messageInputTarget.value : '';
    const ttl = this.hasTtlSelectTarget ? parseInt(this.ttlSelectTarget.value, 10) : 0;
    const views = this.hasViewsSelectTarget ? parseInt(this.viewsSelectTarget.value, 10) : 0;
    const burnAfterReading = this.hasBurnToggleTarget ? this.burnToggleTarget.checked : false;

    const validationError = ValidationService.validate({ message, ttl, views });
    if (validationError) {
      ErrorService.handle(new Error(validationError));
      return;
    }

    if (typeof CryptographyService.encryptMessage !== 'function' ||
        typeof CryptographyService.encryptFiles !== 'function') {
      ErrorService.handle(new Error('Encryption module failed to load.'));
      return;
    }
    const usePassword = this.passwordToggleTarget.checked;
    const password = usePassword ? this.passwordInputTarget.value : '';

    this.encryptButtonTarget.classList.add('loading', 'btn-progress');
    this.encryptButtonTarget.disabled = true;
    this.progressDotsTarget.classList.remove('d-none');
    const originalText = this.encryptButtonTextTarget.textContent;

    try {
      const update = (p) => {
        let text = p.status;
        if (p.details) text += ` ${p.details}`;
        if (p.percentage !== undefined) text += ` (${p.percentage}%)`;
        if (p.speed) text += ` ${p.speed.toFixed(2)} MB/s`;
        if (p.eta) text += ` ETA: ${p.eta.toFixed(1)}s`;
        this.encryptButtonTextTarget.textContent = text;
      };

      let link;
      if (this.selectedFiles.length > 0) {
        link = await CryptographyService.encryptFiles(
          this.selectedFiles,
          message,
          ttl,
          views,
          password,
          burnAfterReading,
          update
        );
      } else {
        update({ percentage: 50, status: 'Encrypting message...' });
        link = await CryptographyService.encryptMessage(message, ttl, views, password, burnAfterReading);
        update({ percentage: 100, status: 'Complete!', speed: 0, eta: 0 });
      }

      this.encryptButtonTarget.classList.remove('loading', 'btn-progress');
      this.encryptButtonTarget.disabled = false;
      this.encryptButtonTextTarget.textContent = originalText;
      this.progressDotsTarget.classList.add('d-none');

      this.encryptedLinkTarget.value = link;

      if (this.hasQrToggleTarget && this.qrToggleTarget.checked) {
        this.qrTabTarget.style.display = '';
        this.qrPanelTarget.style.display = '';
        this.resultTabsTarget.style.display = '';
        this.qrContainerTarget.innerHTML = '';
        new QRCode(this.qrContainerTarget, {
          text: link,
          width: 256,
          height: 256,
          colorDark: '#000000',
          colorLight: '#ffffff',
          correctLevel: QRCode.CorrectLevel.H
        });
      } else {
        if (this.hasQrTabTarget) this.qrTabTarget.style.display = 'none';
        if (this.hasQrPanelTarget) this.qrPanelTarget.style.display = 'none';
      }

      this.resultContainerTarget.classList.remove('d-none');
      if (this.resultMessageTarget) {
        if (usePassword) {
          this.resultMessageTarget.textContent = 'This link requires a password to access. Share both the link and password separately for maximum security.';
        } else {
          this.resultMessageTarget.textContent = 'This link contains the decryption key. Anyone with this link can view your message or download your files.';
        }
      }

      if (this.hasFormTarget) {
        this.formTarget.reset();
      }
      if (document.getElementById('richEditor')) {
        document.getElementById('richEditor').innerHTML = '';
      }
      if (this.hasMessageInputTarget) this.messageInputTarget.value = '';
      this.selectedFiles = [];
      this.renderFiles();
      this.resultContainerTarget.scrollIntoView({ behavior: 'smooth' });
    } catch (error) {
      this.encryptButtonTarget.classList.remove('loading', 'btn-progress');
      this.encryptButtonTarget.disabled = false;
      this.encryptButtonTextTarget.textContent = originalText;
      this.progressDotsTarget.classList.add('d-none');
      ErrorService.handle(error);
    }
  }

  copy() {
    if (!this.hasEncryptedLinkTarget || !this.hasCopyButtonTarget) return;
    const linkInput = this.encryptedLinkTarget;
    linkInput.select();
    document.execCommand('copy');
    const originalText = this.copyButtonTarget.innerHTML;
    this.copyButtonTarget.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1"><path d="M20 6 9 17l-5-5"/></svg> Copied!';
    this.copyButtonTarget.classList.add('btn-success');
    this.copyButtonTarget.classList.remove('btn-outline-primary');
    setTimeout(() => {
      this.copyButtonTarget.innerHTML = originalText;
      this.copyButtonTarget.classList.remove('btn-success');
      this.copyButtonTarget.classList.add('btn-outline-primary');
    }, 2000);
  }
}
