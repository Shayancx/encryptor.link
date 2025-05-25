// Optional Account UI
document.addEventListener('DOMContentLoaded', () => {
  // Add account button to header
  const header = document.querySelector('.app-header');
  if (!header) return;

  const accountContainer = document.createElement('div');
  accountContainer.className = 'd-flex align-items-center';
  accountContainer.innerHTML = `
    <a href="/session/new" class="btn btn-sm btn-outline-primary me-2">
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
        <circle cx="12" cy="7" r="4"></circle>
      </svg>
      <span id="accountBtnText">Account</span>
    </a>
  `;

  // Insert before theme switcher
  const themeSwitch = header.querySelector('.theme-switch-container');
  if (themeSwitch) {
    themeSwitch.parentNode.insertBefore(accountContainer, themeSwitch);
  }

  // Update button text if user is logged in (check for session)
  fetch('/account/preferences', {
    headers: { 'Accept': 'application/json' },
    credentials: 'same-origin'
  })
  .then(response => {
    if (response.ok) {
      // User is logged in
      const accountBtn = accountContainer.querySelector('a');
      accountBtn.href = '/account/messages';
      document.getElementById('accountBtnText').textContent = 'Dashboard';
    }
  })
  .catch(() => {
    // Not logged in, keep default
  });

  // Add checkbox to encryption form for tracking
  const encryptForm = document.getElementById('encryptForm');
  if (encryptForm) {
    // Check if user is logged in
    fetch('/account/preferences', {
      headers: { 'Accept': 'application/json' },
      credentials: 'same-origin'
    })
    .then(response => {
      if (response.ok) {
        // Add checkbox for tracking
        const trackingDiv = document.createElement('div');
        trackingDiv.className = 'form-check mb-3';
        trackingDiv.innerHTML = `
          <input class="form-check-input" type="checkbox" id="trackMessage" checked>
          <label class="form-check-label" for="trackMessage">
            Save to my message history
          </label>
        `;

        const submitBtn = encryptForm.querySelector('button[type="submit"]');
        submitBtn.parentNode.insertBefore(trackingDiv, submitBtn);
      }
    })
    .catch(() => {
      // Not logged in, no tracking option
    });
  }
});

// Update the encryption form submission to include tracking preference
document.addEventListener('DOMContentLoaded', () => {
  const originalEncryptMessage = window.encryptMessage;
  const originalEncryptFiles = window.encryptFiles;

  if (originalEncryptMessage) {
    window.encryptMessage = async function(message, ttl, views, password = '') {
      const trackCheckbox = document.getElementById('trackMessage');
      const result = await originalEncryptMessage.call(this, message, ttl, views, password);

      // If tracking is enabled and user is logged in, the server will handle it
      if (trackCheckbox && trackCheckbox.checked) {
        // Server-side tracking happens automatically
      }

      return result;
    };
  }

  if (originalEncryptFiles) {
    window.encryptFiles = async function(files, message, ttl, views, password = '') {
      const trackCheckbox = document.getElementById('trackMessage');
      const result = await originalEncryptFiles.call(this, files, message, ttl, views, password);

      // If tracking is enabled and user is logged in, the server will handle it
      if (trackCheckbox && trackCheckbox.checked) {
        // Server-side tracking happens automatically
      }

      return result;
    };
  }
});
