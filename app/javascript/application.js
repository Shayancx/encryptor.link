// Entry point for the build script in your package.json
import "@hotwired/stimulus"
import "./controllers"


console.log("Encryptor.link application loaded!");

// Rich Text Editor functionality
document.addEventListener('DOMContentLoaded', function() {
  const editor = document.getElementById('richEditor');
  const hiddenInput = document.getElementById('hidden_message');
  const expandButton = document.getElementById('expandEditor');
  const editorContainer = document.getElementById('richEditorContainer');

  // Function to toggle expanded view
  expandButton.addEventListener('click', function() {
    editorContainer.classList.toggle('expanded');

    // Update expand button icon
    if (editorContainer.classList.contains('expanded')) {
      this.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M4 14h6v6M20 10h-6V4M14 10l7-7M3 21l7-7"/>
        </svg>
      `;
      this.title = "Collapse editor";
    } else {
      this.innerHTML = `
        <svg xmlns="http://www.w3.org/2000/svg" width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
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
        } else if (command === 'code') {
          // Handle code formatting
          const selection = window.getSelection();
          if (selection.rangeCount > 0) {
            const range = selection.getRangeAt(0);
            const selectedText = range.toString();

            // Check if already wrapped in code
            const parentElement = range.commonAncestorContainer.parentElement;
            if (parentElement && parentElement.tagName === 'CODE') {
              // Unwrap the code element
              const text = document.createTextNode(parentElement.textContent);
              parentElement.parentNode.replaceChild(text, parentElement);
            } else if (selectedText) {
              // Wrap selection in code element
              const codeElement = document.createElement('code');
              codeElement.textContent = selectedText;
              range.deleteContents();
              range.insertNode(codeElement);

              // Move cursor after the code element
              range.setStartAfter(codeElement);
              range.setEndAfter(codeElement);
              selection.removeAllRanges();
              selection.addRange(range);
            }
          }
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
        } else if (command === 'code') {
          // Check if current selection is within a code element
          const selection = window.getSelection();
          if (selection.rangeCount > 0) {
            const range = selection.getRangeAt(0);
            const parentElement = range.commonAncestorContainer.parentElement;
            const isInCode = parentElement && (parentElement.tagName === 'CODE' || parentElement.closest('code'));
            button.classList.toggle('active', isInCode);
          }
        } else {
          button.classList.toggle('active', document.queryCommandState(command));
        }
      });
    }

    // Watch for formatting changes to update button states
    editor.addEventListener('keyup', updateButtonStates);
    editor.addEventListener('mouseup', updateButtonStates);
    editor.addEventListener('input', updateHiddenInput);

    // Function to update the hidden input with HTML
    function updateHiddenInput() {
      hiddenInput.value = editor.innerHTML;
    }

    // Initialize editor with focus
    setTimeout(() => {
      editor.focus();
    }, 100);
  }
});


    // Watch for formatting changes to update button states
    editor.addEventListener('keyup', updateButtonStates);
    editor.addEventListener('mouseup', updateButtonStates);
    editor.addEventListener('input', updateHiddenInput);

    // Function to update button active states
    function updateButtonStates() {
      buttons.forEach(button => {
        const command = button.dataset.command;

        if (command === 'h1' || command === 'h2' || command === 'h3') {
          const formatBlock = document.queryCommandValue('formatBlock');
          button.classList.toggle('active', formatBlock === command);
        } else {
          button.classList.toggle('active', document.queryCommandState(command));
        }
      });
    }

    // Function to update the hidden input with HTML
    function updateHiddenInput() {
      if (hiddenInput) {
        hiddenInput.value = editor.innerHTML;
      }
    }
  }
});
