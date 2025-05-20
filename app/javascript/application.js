// Entry point for the build script in your package.json
import "@hotwired/stimulus"
import "./controllers"
import "trix"
import "@rails/actiontext"

// Custom Trix configuration
document.addEventListener("trix-initialize", function(event) {
  // To preserve the content formatting when encrypting and decrypting
  const trixEditor = event.target;

  // Additional configuration can be added here
});

console.log("Encryptor.link application loaded!");

// Rich Text Editor functionality
document.addEventListener('DOMContentLoaded', function() {
  const editor = document.getElementById('richEditor');
  if (editor) {
    const toolbar = document.querySelector('.rich-editor-toolbar');
    const buttons = toolbar.querySelectorAll('button');
    const hiddenInput = document.getElementById('hidden_message');

    // Initialize the content
    updateHiddenInput();

    // Add event listeners to all toolbar buttons
    buttons.forEach(button => {
      button.addEventListener('click', function(e) {
        e.preventDefault();
        const command = this.dataset.command;

        if (command === 'h1' || command === 'h2' || command === 'h3') {
          document.execCommand('formatBlock', false, command);
        } else if (command === 'createLink') {
          const url = prompt('Enter the link URL:');
          if (url) document.execCommand(command, false, url);
        } else {
          document.execCommand(command, false, null);
        }

        // Update active states
        updateButtonStates();

        // Update hidden input with HTML content
        updateHiddenInput();
      });
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
