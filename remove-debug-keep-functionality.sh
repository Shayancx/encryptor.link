#!/bin/bash

set -e

echo "🧹 Removing debug functionality while keeping all working features..."

# Remove debug panel from HTML but keep all layout and functionality
echo "📄 Cleaning up HTML - removing debug panel..."

cat > app/views/encryptions/new.html.erb << 'EOF'
<div class="gh-card">
  <div class="gh-card-header">
    <h3>Create Encrypted Message</h3>
  </div>
  <div class="gh-card-body">
    <form id="encryptForm">
      <div class="mb-3">
        <label for="richEditor" class="form-label">Message</label>

        <div class="rich-text-layout">
          <!-- Main text editor container - now narrower to accommodate settings -->
          <div class="rich-text-container" id="richTextContainer">
            <div class="rich-editor-container" id="richEditorContainer">
              <div class="rich-editor-toolbar">
                <button type="button" class="rich-editor-button" data-command="bold" title="Bold">B</button>
                <button type="button" class="rich-editor-button" data-command="italic" title="Italic">I</button>
                <button type="button" class="rich-editor-button" data-command="strikeThrough" title="Strikethrough">S</button>
                <button type="button" class="rich-editor-button" data-command="insertHTML" data-value="<code>code</code>" title="Code">&lt;/&gt;</button>

                <div class="rich-editor-divider"></div>

                <button type="button" class="rich-editor-button" data-command="formatBlock" data-value="h1" title="Heading 1">H1</button>
                <button type="button" class="rich-editor-button" data-command="formatBlock" data-value="h2" title="Heading 2">H2</button>
                <button type="button" class="rich-editor-button" data-command="formatBlock" data-value="h3" title="Heading 3">H3</button>

                <div class="rich-editor-divider"></div>

                <button type="button" class="rich-editor-button" data-command="insertUnorderedList" title="Bullet List">•</button>
                <button type="button" class="rich-editor-button" data-command="insertOrderedList" title="Numbered List">1.</button>
                <button type="button" class="rich-editor-button" data-command="createLink" title="Insert Link">🔗</button>

                <button type="button" class="rich-editor-expand" id="expandEditor" title="Toggle expanded view">
                  <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/>
                  </svg>
                </button>
              </div>
              <div id="richEditor" class="rich-editor-content" contenteditable="true" placeholder="Enter your message here..."></div>
              <input type="hidden" id="hidden_message" name="message">
            </div>
          </div>

          <!-- Settings sidebar - properly spaced and organized -->
          <div class="rich-text-settings" id="richTextSettings">
            <!-- Password Protection Panel -->
            <div class="gh-setting-panel mb-3">
              <div class="gh-setting-header">
                <div class="gh-setting-title">
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                    <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
                  </svg>
                  Password Protection
                </div>
                <div class="gh-setting-description">Require a password to access this content</div>
              </div>
              <div class="gh-setting-controls">
                <div class="form-check form-switch">
                  <input class="form-check-input" type="checkbox" id="passwordToggle">
                  <label class="form-check-label" for="passwordToggle">Enable password</label>
                </div>
                <div id="passwordContainer" class="mt-2" style="display:none;">
                  <input type="password" class="form-control" id="passwordInput" placeholder="Enter password...">
                </div>
              </div>
            </div>

            <!-- Expiration Panel -->
            <div class="gh-setting-panel mb-3">
              <div class="gh-setting-header">
                <div class="gh-setting-title">
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"></circle>
                    <line x1="12" y1="8" x2="12" y2="12"></line>
                    <line x1="12" y1="16" x2="12.01" y2="16"></line>
                  </svg>
                  Expiration Time
                </div>
                <div class="gh-setting-description">Message expires automatically after</div>
              </div>
              <div class="gh-setting-controls">
                <select class="form-select" id="ttlSelect">
                  <option value="3600">1 hour</option>
                  <option value="86400" selected>1 day</option>
                  <option value="604800">1 week</option>
                </select>
              </div>
            </div>

            <!-- View Limit Panel -->
            <div class="gh-setting-panel mb-3">
              <div class="gh-setting-header">
                <div class="gh-setting-title">
                  <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="2" y="2" width="20" height="20" rx="5" ry="5"></rect>
                    <path d="M8.5 7h7l3.5 3.5-7 7-7-7L8.5 7z"></path>
                  </svg>
                  View Limit
                </div>
                <div class="gh-setting-description">Self-destruct after this many views</div>
              </div>
              <div class="gh-setting-controls">
                <select class="form-select" id="viewsSelect">
                  <option value="1" selected>1 view</option>
                  <option value="2">2 views</option>
                  <option value="3">3 views</option>
                  <option value="5">5 views</option>
                </select>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="mb-3">
        <label class="form-label">Attach Files (optional, max 1000MB total)</label>
        <div id="dropArea" class="file-upload-area">
          <div id="dropAreaDefault">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="mb-2">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
              <polyline points="17 8 12 3 7 8"></polyline>
              <line x1="12" y1="3" x2="12" y2="15"></line>
            </svg>
            <p class="mb-1">Drag & drop files here, or click to select</p>
            <small class="text-muted">Files are encrypted in your browser before uploading</small>
          </div>
          <input type="file" id="fileInput" style="display:none;" multiple>
        </div>
      </div>

      <!-- Files table with pagination -->
      <div id="filesContainer" class="mt-3" style="display:none;">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <div class="gh-setting-title">Selected Files</div>
          <span id="totalSize" class="text-muted">Total: 0 MB</span>
        </div>

        <div class="gh-file-list">
          <div id="filesListBody">
            <!-- File items will be added dynamically -->
          </div>
        </div>

        <!-- Pagination controls -->
        <div id="pagination" class="gh-pagination mt-2"></div>
      </div>

      <div class="d-grid mt-4">
        <button type="submit" class="btn btn-primary">
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
          </svg>
          Encrypt & Generate Link
        </button>
      </div>
    </form>

    <div id="resultContainer" class="mt-4 d-none">
      <div class="gh-flash gh-flash-success">
        <div class="gh-flash-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
          </svg>
        </div>
        <div class="gh-flash-content">
          <div class="gh-flash-title">Your encrypted link has been generated</div>
          <div class="input-group mb-2 mt-2">
            <input type="text" id="encryptedLink" class="form-control" readonly>
            <button class="btn btn-outline-primary" type="button" id="copyButton">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1">
                <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
              </svg>
              Copy
            </button>
          </div>
          <p class="mb-0 text-muted small" id="resultMessage">This link contains the decryption key. Anyone with this link can view your message or download your files.</p>
        </div>
      </div>
    </div>
  </div>
</div>

<script type="module">
  // Import encryption module
  import { encryptMessage, encryptFiles } from "/encrypt.js";

  // Rich Text Editor functionality
  document.addEventListener('DOMContentLoaded', function() {
    const editor = document.getElementById('richEditor');
    const hiddenInput = document.getElementById('hidden_message');
    const expandButton = document.getElementById('expandEditor');
    const editorContainer = document.getElementById('richEditorContainer');
    const richTextContainer = document.getElementById('richTextContainer');
    const richTextSettings = document.getElementById('richTextSettings');

    // Function to toggle expanded view
    expandButton.addEventListener('click', function() {
      editorContainer.classList.toggle('expanded');
      richTextSettings.classList.toggle('hidden');

      // Update expand button icon
      if (editorContainer.classList.contains('expanded')) {
        this.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M4 14h6v6M20 10h-6V4M14 10l7-7M3 21l7-7"/>
          </svg>
        `;
        this.title = "Collapse editor";
      } else {
        this.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/>
          </svg>
        `;
        this.title = "Expand editor";
      }
    });

    if (editor && hiddenInput) {
      // Initialize click handlers for toolbar buttons
      const buttons = document.querySelectorAll('.rich-editor-button');

      buttons.forEach(button => {
        button.addEventListener('click', function(e) {
          e.preventDefault();

          const command = this.getAttribute('data-command');
          const value = this.getAttribute('data-value') || null;

          // Handle special cases
          if (command === 'createLink') {
            const url = prompt('Enter the link URL:');
            if (url) {
              document.execCommand(command, false, url);
            }
          } else if (command === 'formatBlock') {
            document.execCommand(command, false, value);
          } else if (command === 'insertHTML') {
            document.execCommand(command, false, value);
          } else {
            // Standard commands
            document.execCommand(command, false, null);
          }

          // Update active states
          updateButtonStates();

          // Update hidden input with the content
          updateHiddenInput();

          // Focus back on editor
          editor.focus();
        });
      });

      // Update button active states based on current selection
      function updateButtonStates() {
        buttons.forEach(button => {
          const command = button.getAttribute('data-command');

          if (command === 'formatBlock') {
            const value = button.getAttribute('data-value');
            const formatBlock = document.queryCommandValue('formatBlock');
            button.classList.toggle('active', formatBlock.toLowerCase() === value);
          } else {
            button.classList.toggle('active', document.queryCommandState(command));
          }
        });
      }

      // Update hidden input when editor content changes
      editor.addEventListener('input', updateHiddenInput);
      editor.addEventListener('keyup', updateButtonStates);
      editor.addEventListener('mouseup', updateButtonStates);

      // Function to update hidden input
      function updateHiddenInput() {
        hiddenInput.value = editor.innerHTML;
      }

      // Initialize editor with focus
      setTimeout(() => {
        editor.focus();
      }, 100);
    }
  });

  // File handling variables
  let selectedFiles = [];
  const MAX_SIZE = 1000 * 1024 * 1024; // 1000MB in bytes
  let currentPage = 1;
  const itemsPerPage = 5;

  // File icons - GitHub-style icons
  const fileIcons = {
    // Document types
    'pdf': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor"><path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5Z"/><polyline points="14 4 9 4 9 0"/></svg>',
    'doc': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor"><path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5Z"/><polyline points="14 4 9 4 9 0"/></svg>',
    'docx': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor"><path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5Z"/><polyline points="14 4 9 4 9 0"/></svg>',

    // Image files
    'jpg': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor"><rect width="14" height="14" x="1" y="1" rx="2"/><circle cx="5" cy="5" r="1"/><path d="m15 11-5-5L2 15"/></svg>',
    'jpeg': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor"><rect width="14" height="14" x="1" y="1" rx="2"/><circle cx="5" cy="5" r="1"/><path d="m15 11-5-5L2 15"/></svg>',
    'png': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor"><rect width="14" height="14" x="1" y="1" rx="2"/><circle cx="5" cy="5" r="1"/><path d="m15 11-5-5L2 15"/></svg>',

    // E-book files
    'epub': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor"><path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5Z"/><polyline points="14 4 9 4 9 0"/><path d="M6 7h4M6 9h4M6 11h2"/></svg>',
    'mobi': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor"><path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5Z"/><polyline points="14 4 9 4 9 0"/><path d="M6 7h4M6 9h4M6 11h2"/></svg>',

    // Default for other files
    'default': '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16" fill="none" stroke="currentColor"><path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5Z"/></svg>'
  };

  // Set up file drag & drop
  const dropArea = document.getElementById('dropArea');
  const fileInput = document.getElementById('fileInput');
  const dropAreaDefault = document.getElementById('dropAreaDefault');
  const filesContainer = document.getElementById('filesContainer');
  const filesListBody = document.getElementById('filesListBody');
  const totalSizeElement = document.getElementById('totalSize');
  const paginationElement = document.getElementById('pagination');
  const passwordToggle = document.getElementById('passwordToggle');
  const passwordContainer = document.getElementById('passwordContainer');
  const passwordInput = document.getElementById('passwordInput');

  // Setup password toggle
  passwordToggle.addEventListener('change', function() {
    passwordContainer.style.display = this.checked ? 'block' : 'none';
    if (!this.checked) {
      passwordInput.value = '';
    }
  });

  // Prevent default behaviors
  ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
    dropArea.addEventListener(eventName, preventDefaults, false);
  });

  function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  // Highlight drop area when dragging file over it
  ['dragenter', 'dragover'].forEach(eventName => {
    dropArea.addEventListener(eventName, highlight, false);
  });

  ['dragleave', 'drop'].forEach(eventName => {
    dropArea.addEventListener(eventName, unhighlight, false);
  });

  function highlight() {
    dropArea.classList.add('dragover');
  }

  function unhighlight() {
    dropArea.classList.remove('dragover');
  }

  // Handle dropped files
  dropArea.addEventListener('drop', handleDrop, false);

  function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    if (files.length) {
      handleFiles(Array.from(files));
    }
  }

  // Handle file input
  dropArea.addEventListener('click', () => {
    fileInput.click();
  });

  fileInput.addEventListener('change', (e) => {
    if (e.target.files.length) {
      handleFiles(Array.from(e.target.files));
    }
  });

  // Process selected files
  function handleFiles(files) {
    // Calculate total size including existing files
    const existingSize = selectedFiles.reduce((total, file) => total + file.size, 0);
    const newSize = files.reduce((total, file) => total + file.size, 0);
    const totalSize = existingSize + newSize;

    if (totalSize > MAX_SIZE) {
      alert(`Total file size exceeds the 1000MB limit. Please select fewer or smaller files.`);
      return;
    }

    // Add new files to the array
    selectedFiles = [...selectedFiles, ...files];

    // Show files container
    filesContainer.style.display = 'block';

    // Update the file list and pagination
    updateFilesList();
  }

  // Format file size
  function formatFileSize(bytes) {
    if (bytes < 1024) return bytes + ' bytes';
    else if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    else if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    else return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
  }

  // Update files list with GitHub-style file list
  function updateFilesList() {
    // Update total size
    const totalSize = selectedFiles.reduce((total, file) => total + file.size, 0);
    totalSizeElement.textContent = `Total: ${formatFileSize(totalSize)}`;

    // Calculate pagination
    const totalPages = Math.ceil(selectedFiles.length / itemsPerPage);
    const startIndex = (currentPage - 1) * itemsPerPage;
    const endIndex = Math.min(startIndex + itemsPerPage, selectedFiles.length);
    const currentFiles = selectedFiles.slice(startIndex, endIndex);

    // Clear the list
    filesListBody.innerHTML = '';

    // Add file items
    currentFiles.forEach((file, index) => {
      const actualIndex = startIndex + index;
      const extension = file.name.split('.').pop().toLowerCase();
      const iconSvg = fileIcons[extension] || fileIcons['default'];

      const fileItem = document.createElement('div');
      fileItem.className = 'gh-file-item';
      fileItem.innerHTML = `
        <div class="gh-file-details">
          <div class="gh-file-icon">${iconSvg}</div>
          <div class="gh-file-name">${file.name}</div>
          <div class="gh-file-meta">
            <span class="gh-file-size">${formatFileSize(file.size)}</span>
            <span class="gh-file-type">${file.type || 'Unknown'}</span>
          </div>
        </div>
        <div class="gh-file-actions">
          <button type="button" class="btn btn-sm btn-outline-danger btn-icon" data-index="${actualIndex}">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M3 6h18"></path>
              <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path>
            </svg>
          </button>
        </div>
      `;

      // Add remove button event
      const removeButton = fileItem.querySelector('button');
      removeButton.addEventListener('click', (e) => {
        const index = parseInt(e.currentTarget.dataset.index);
        selectedFiles.splice(index, 1);
        updateFilesList();

        // Hide the container if no files
        if (selectedFiles.length === 0) {
          filesContainer.style.display = 'none';
        }
      });

      filesListBody.appendChild(fileItem);
    });

    // Update pagination controls
    updatePagination(totalPages);
  }

  // Update pagination controls
  function updatePagination(totalPages) {
    paginationElement.innerHTML = '';

    if (totalPages <= 1) {
      return;
    }

    // Previous button
    const prevButton = document.createElement('a');
    prevButton.href = '#';
    prevButton.className = `gh-page-link ${currentPage === 1 ? 'disabled' : ''}`;
    prevButton.innerHTML = '&laquo;';
    prevButton.addEventListener('click', (e) => {
      e.preventDefault();
      if (currentPage > 1) {
        currentPage--;
        updateFilesList();
      }
    });

    const prevItem = document.createElement('div');
    prevItem.className = 'gh-page-item';
    prevItem.appendChild(prevButton);
    paginationElement.appendChild(prevItem);

    // Page numbers
    for (let i = 1; i <= totalPages; i++) {
      const pageLink = document.createElement('a');
      pageLink.href = '#';
      pageLink.className = `gh-page-link ${i === currentPage ? 'active' : ''}`;
      pageLink.textContent = i;
      pageLink.addEventListener('click', (e) => {
        e.preventDefault();
        currentPage = i;
        updateFilesList();
      });

      const pageItem = document.createElement('div');
      pageItem.className = 'gh-page-item';
      pageItem.appendChild(pageLink);
      paginationElement.appendChild(pageItem);
    }

    // Next button
    const nextButton = document.createElement('a');
    nextButton.href = '#';
    nextButton.className = `gh-page-link ${currentPage === totalPages ? 'disabled' : ''}`;
    nextButton.innerHTML = '&raquo;';
    nextButton.addEventListener('click', (e) => {
      e.preventDefault();
      if (currentPage < totalPages) {
        currentPage++;
        updateFilesList();
      }
    });

    const nextItem = document.createElement('div');
    nextItem.className = 'gh-page-item';
    nextItem.appendChild(nextButton);
    paginationElement.appendChild(nextItem);
  }

  // Handle form submission
  document.getElementById('encryptForm').addEventListener('submit', async function(e) {
    e.preventDefault();

    // Get message from the rich text editor
    const message = document.getElementById('hidden_message').value;

    const ttl = parseInt(document.getElementById('ttlSelect').value);
    const views = parseInt(document.getElementById('viewsSelect').value);
    const usePassword = passwordToggle.checked;
    const password = usePassword ? passwordInput.value : '';

    // Check if either message or files are provided
    if ((!message || message.trim() === '') && selectedFiles.length === 0) {
      alert('Please enter a message or select at least one file.');
      return;
    }

    // If password protection is enabled, validate the password
    if (usePassword && (!password || password.length < 1)) {
      alert('Please enter a password.');
      return;
    }

    try {
      // Show loading state
      const submitBtn = this.querySelector('button[type="submit"]');
      const originalText = submitBtn.innerHTML;
      submitBtn.disabled = true;
      submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Processing...';

      let link;

      if (selectedFiles.length > 0) {
        // Encrypt files and message
        link = await encryptFiles(
          selectedFiles,
          message,
          ttl,
          views,
          password
        );
      } else {
        // Encrypt text message only
        link = await encryptMessage(message, ttl, views, password);
      }

      // Display the result
      document.getElementById('encryptedLink').value = link;
      document.getElementById('resultContainer').classList.remove('d-none');

      // Update result message based on password protection
      const resultMessage = document.getElementById('resultMessage');
      if (usePassword) {
        resultMessage.textContent = 'This link requires a password to access. Share both the link and password separately for maximum security.';
      } else {
        resultMessage.textContent = 'This link contains the decryption key. Anyone with this link can view your message or download your files.';
      }

      // Reset form state
      submitBtn.disabled = false;
      submitBtn.innerHTML = originalText;
      this.reset();

      // Reset editor expansion
      const editorContainer = document.getElementById('richEditorContainer');
      const richTextSettings = document.getElementById('richTextSettings');
      const expandButton = document.getElementById('expandEditor');

      if (editorContainer.classList.contains('expanded')) {
        editorContainer.classList.remove('expanded');
        richTextSettings.classList.remove('hidden');
        expandButton.innerHTML = `
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/>
          </svg>
        `;
        expandButton.title = "Expand editor";
      }

      // Clear the rich text editor
      document.getElementById('richEditor').innerHTML = '';
      document.getElementById('hidden_message').value = '';

      selectedFiles = [];
      filesContainer.style.display = 'none';
      passwordContainer.style.display = 'none';

      // Scroll to the result
      document.getElementById('resultContainer').scrollIntoView({ behavior: 'smooth' });
    } catch (error) {
      alert('Error: ' + error.message);
      console.error(error);
    }
  });

  // Handle copy button
  document.getElementById('copyButton').addEventListener('click', function() {
    const linkInput = document.getElementById('encryptedLink');
    linkInput.select();
    document.execCommand('copy');

    // Visual feedback
    const originalText = this.innerHTML;
    this.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="me-1"><path d="M20 6 9 17l-5-5"/></svg> Copied!';
    this.classList.add('btn-success');
    this.classList.remove('btn-outline-primary');

    setTimeout(() => {
      this.innerHTML = originalText;
      this.classList.remove('btn-success');
      this.classList.add('btn-outline-primary');
    }, 2000);
  });
</script>
EOF

# Clean up encrypt.js - remove debug but keep all functionality
echo "🔐 Cleaning up encrypt.js - removing debug logging..."

cat > public/encrypt.js << 'EOF'
// Web Crypto API wrapper for encryption
async function encryptMessage(message, ttl, views, password = '') {
  try {
    // Generate a random encryption key
    const key = await generateEncryptionKey(password);

    // Generate a random IV
    const iv = window.crypto.getRandomValues(new Uint8Array(12));

    // Encrypt the message
    const encrypted = await encryptData(message, key.key, iv);

    // Prepare API payload
    const payload = {
      ciphertext: Base64.encode(encrypted),
      nonce: Base64.encode(iv),
      ttl: ttl,
      views: views,
      password_protected: !!password
    };

    // Add password salt if password is provided
    if (password) {
      payload.password_salt = Base64.encode(key.salt);
    }

    // Send the encrypted data to the server
    const response = await fetch('/encrypt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Failed to create encrypted message: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    // Generate link with the key in the fragment
    let link = window.location.origin + '/' + data.id;

    // For non-password protected content, add the key to the fragment
    if (!password) {
      const exportedKey = await window.crypto.subtle.exportKey('raw', key.key);
      const keyBase64 = Base64.encode(exportedKey);
      link += '#' + keyBase64;
    }

    return link;
  } catch (error) {
    console.error('Encryption error:', error);
    throw error;
  }
}

// Encrypt multiple files
async function encryptFiles(files, message, ttl, views, password = '') {
  try {
    // Generate a random encryption key
    const key = await generateEncryptionKey(password);

    // Generate a random IV
    const iv = window.crypto.getRandomValues(new Uint8Array(12));

    // Create API payload
    const payload = {
      nonce: Base64.encode(iv),
      ttl: ttl,
      views: views,
      password_protected: !!password,
      files: []
    };

    // Add password salt if password is provided
    if (password) {
      payload.password_salt = Base64.encode(key.salt);
    }

    // Encrypt message if present
    if (message && message.trim() !== '') {
      const encryptedMessage = await encryptData(message, key.key, iv);
      payload.ciphertext = Base64.encode(encryptedMessage);
    } else {
      payload.ciphertext = '';
    }

    // Process each file
    for (let i = 0; i < files.length; i++) {
      const file = files[i];

      try {
        // Read the file as an ArrayBuffer
        const fileData = await readFileAsArrayBuffer(file);

        // Encrypt the file data
        const encryptedFile = await encryptData(fileData, key.key, iv);

        // Encode to Base64
        const encodedFile = Base64.encode(encryptedFile);

        // Add the encrypted file to the payload
        payload.files.push({
          data: encodedFile,
          name: file.name,
          type: file.type || 'application/octet-stream',
          size: file.size
        });
      } catch (fileError) {
        throw new Error(`Failed to process file "${file.name}": ${fileError.message}`);
      }
    }

    // Send the encrypted data to the server
    const response = await fetch('/encrypt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Failed to create encrypted message with files: ${response.status} ${response.statusText} - ${errorText}`);
    }

    const data = await response.json();

    // Generate link with the key in the fragment
    let link = window.location.origin + '/' + data.id;

    // For non-password protected content, add the key to the fragment
    if (!password) {
      const exportedKey = await window.crypto.subtle.exportKey('raw', key.key);
      const keyBase64 = Base64.encode(exportedKey);
      link += '#' + keyBase64;
    }

    return link;
  } catch (error) {
    console.error('File encryption error:', error);
    throw error;
  }
}

// Generate an encryption key
async function generateEncryptionKey(password = '') {
  try {
    if (password) {
      // Generate a random salt
      const salt = window.crypto.getRandomValues(new Uint8Array(16));

      // Convert password to a key using PBKDF2
      const passwordKey = await window.crypto.subtle.importKey(
        'raw',
        new TextEncoder().encode(password),
        { name: 'PBKDF2' },
        false,
        ['deriveKey']
      );

      // Derive the actual encryption key
      const key = await window.crypto.subtle.deriveKey(
        {
          name: 'PBKDF2',
          salt: salt,
          iterations: 100000,
          hash: 'SHA-256'
        },
        passwordKey,
        { name: 'AES-GCM', length: 256 },
        true,
        ['encrypt']
      );

      return { key, salt };
    } else {
      // Generate a random key
      const key = await window.crypto.subtle.generateKey(
        { name: 'AES-GCM', length: 256 },
        true,
        ['encrypt']
      );

      return { key };
    }
  } catch (error) {
    throw error;
  }
}

// Encrypt data with AES-GCM
async function encryptData(data, key, iv) {
  try {
    // Convert string to ArrayBuffer if needed
    let dataBuffer;
    if (typeof data === 'string') {
      dataBuffer = new TextEncoder().encode(data);
    } else {
      dataBuffer = new Uint8Array(data);
    }

    // Encrypt using AES-GCM
    const encrypted = await window.crypto.subtle.encrypt(
      { name: 'AES-GCM', iv: iv },
      key,
      dataBuffer
    );

    return encrypted;
  } catch (error) {
    throw error;
  }
}

// Read a file as ArrayBuffer
function readFileAsArrayBuffer(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => {
      resolve(reader.result);
    };

    reader.onerror = () => {
      const errorMsg = `Failed to read file: ${file.name}`;
      reject(new Error(errorMsg));
    };

    reader.readAsArrayBuffer(file);
  });
}

// Optimized Base64 utility object that handles large files efficiently
const Base64 = {
  encode: function(arrayBuffer) {
    try {
      // For large files, use chunked encoding to avoid call stack limits
      const bytes = new Uint8Array(arrayBuffer);
      const chunkSize = 0x8000; // 32KB chunks

      if (bytes.length <= chunkSize) {
        // For small files, use the original method
        const result = btoa(String.fromCharCode.apply(null, bytes));
        return result;
      }

      // For large files, process in chunks
      let result = '';
      for (let i = 0; i < bytes.length; i += chunkSize) {
        const chunk = bytes.subarray(i, i + chunkSize);
        result += String.fromCharCode.apply(null, chunk);
      }

      const encodedResult = btoa(result);
      return encodedResult;
    } catch (error) {
      throw new Error(`Base64 encoding failed: ${error.message}`);
    }
  },

  decode: function(base64) {
    try {
      const binaryString = atob(base64);
      const bytes = new Uint8Array(binaryString.length);
      for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
      }
      return bytes.buffer;
    } catch (error) {
      throw new Error(`Base64 decoding failed: ${error.message}`);
    }
  }
};

// Export the functions
export { encryptMessage, encryptFiles };
EOF

# Clean up server-side controller - keep error handling but remove excessive debug
echo "🖥️ Cleaning up server-side controller..."

cat > app/controllers/encryptions_controller.rb << 'EOF'
class EncryptionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [ :create ]

  def new
    render :new
  end

  def create
    # Validate required parameters
    unless params[:nonce].present?
      render json: { error: "Nonce is required" }, status: :unprocessable_entity
      return
    end

    unless params[:ttl].present? && params[:views].present?
      render json: { error: "TTL and views are required" }, status: :unprocessable_entity
      return
    end

    begin
      # Create the main payload record with explicit boolean conversion for password_protected
      payload = EncryptedPayload.new(
        ciphertext: params[:ciphertext].present? ? Base64.strict_decode64(params[:ciphertext]) : "",
        nonce: Base64.strict_decode64(params[:nonce]),
        expires_at: Time.current + params[:ttl].to_i.seconds,
        remaining_views: params[:views].to_i,
        password_protected: ActiveModel::Type::Boolean.new.cast(params[:password_protected]),
        password_salt: params[:password_salt].present? ? Base64.strict_decode64(params[:password_salt]) : nil
      )

      # Log for debugging
      Rails.logger.info "Creating payload with password_protected=#{payload.password_protected?}"

      # Wrap in a transaction to ensure all files are saved or none
      ActiveRecord::Base.transaction do
        payload.save!

        # Handle multiple files if present
        if params[:files].present? && params[:files].is_a?(Array)
          params[:files].each_with_index do |file, index|
            begin
              encrypted_file = payload.encrypted_files.build(
                file_data: file[:data],
                file_name: file[:name],
                file_type: file[:type],
                file_size: file[:size].to_i
              )
              encrypted_file.save!
            rescue => file_error
              Rails.logger.error "ERROR saving file #{index + 1}: #{file_error.message}"
              raise file_error
            end
          end
        end
      end

      render json: { id: payload.id, password_protected: payload.password_protected }
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "Validation errors: #{e.record.errors.full_messages.join(', ')}"
      render json: { error: e.record.errors.full_messages.join(', ') }, status: :unprocessable_entity
    rescue => e
      Rails.logger.error "Error creating encrypted payload: #{e.class}: #{e.message}"
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end
end
EOF

# Remove debug styles from CSS
echo "🎨 Cleaning up CSS - removing debug panel styles..."

cat > app/assets/stylesheets/components/_settings_panel.scss << 'EOF'
// Settings panel styles - proper spacing, no overlapping
.gh-setting-panel {
  background-color: var(--gh-bg-secondary);
  border: 1px solid var(--gh-border-color);
  border-radius: 8px;
  padding: 20px;
  margin-bottom: 20px;
  transition: all 0.2s ease;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);

  &:hover {
    border-color: var(--gh-accent-color);
    box-shadow: 0 2px 8px rgba(var(--gh-accent-color), 0.15);
    transform: translateY(-1px);
  }

  &:last-child {
    margin-bottom: 0;
  }
}

.gh-setting-header {
  margin-bottom: 16px;
}

.gh-setting-title {
  font-weight: 600;
  font-size: 15px;
  margin-bottom: 6px;
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--gh-text-primary);
  line-height: 1.3;

  svg {
    flex-shrink: 0;
    opacity: 0.8;
  }
}

.gh-setting-description {
  color: var(--gh-text-secondary);
  font-size: 13px;
  line-height: 1.4;
  margin: 0;
}

.gh-setting-controls {
  .form-select {
    width: 100%;
    font-size: 14px;
  }

  .form-check {
    margin-bottom: 0;

    .form-check-label {
      font-size: 14px;
      color: var(--gh-text-primary);
    }
  }

  .form-control {
    margin-top: 12px;
    font-size: 14px;
  }
}

// Rich text layout adjustments - make editor narrower to accommodate settings
.rich-text-layout {
  display: flex;
  gap: 24px;
  margin-bottom: 16px;

  @media (max-width: 1200px) {
    flex-direction: column;
    gap: 16px;
  }
}

.rich-text-container {
  flex: 1;
  min-width: 0;
  max-width: calc(100% - 280px); // Make room for settings sidebar
  transition: all 0.3s ease;

  &.expanded {
    max-width: 100%;
  }

  @media (max-width: 1200px) {
    max-width: 100%;
  }
}

.rich-text-settings {
  width: 260px;
  flex-shrink: 0;
  transition: all 0.3s ease;

  &.hidden {
    display: none;
  }

  @media (max-width: 1200px) {
    width: 100%;
  }
}

// Ensure rich editor container has proper dimensions
.rich-editor-container {
  border: 1px solid var(--gh-border-color);
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.rich-editor-content {
  min-height: 200px;
  padding: 16px;
  font-size: 14px;
  line-height: 1.6;
}
EOF

echo "✅ Debug functionality removed successfully!"
echo ""
echo "🎯 What was preserved:"
echo "   ✅ Perfect layout with properly spaced settings panels"
echo "   ✅ File encryption with chunked Base64 encoding"
echo "   ✅ Password protection functionality"
echo "   ✅ Rich text editor with all formatting tools"
echo "   ✅ Drag & drop file handling"
echo "   ✅ File pagination and management"
echo "   ✅ Error handling and validation"
echo "   ✅ All CSS styling and responsive design"
echo ""
echo "🧹 What was removed:"
echo "   ❌ Debug panel and logging interface"
echo "   ❌ Verbose console logging"
echo "   ❌ Development-only debug functions"
echo "   ❌ Excessive server-side logging"
echo ""
echo "🚀 Your app is now production-ready with clean, optimized code!"
echo "   All functionality remains intact without debug clutter."
