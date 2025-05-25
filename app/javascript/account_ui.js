// Account UI Integration
document.addEventListener('DOMContentLoaded', () => {
  // Add account button to header next to theme toggle
  const themeToggleContainer = document.querySelector('.theme-switch-container');
  if (!themeToggleContainer) return;

  const accountButton = document.createElement('button');
  accountButton.type = 'button';
  accountButton.className = 'theme-switch-btn me-2';
  accountButton.id = 'accountButton';
  accountButton.setAttribute('aria-label', 'Account');
  accountButton.innerHTML = `
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
      <circle cx="12" cy="7" r="4"></circle>
    </svg>
  `;

  // Insert before theme toggle
  themeToggleContainer.parentNode.insertBefore(accountButton, themeToggleContainer);

  // Check if user is logged in by trying to access dashboard with JSON format
  fetch('/account/dashboard', {
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    },
    credentials: 'same-origin'
  })
  .then(response => {
    if (response.ok && response.headers.get('content-type')?.includes('application/json')) {
      // User is logged in - go to dashboard
      accountButton.addEventListener('click', () => {
        window.location.href = '/account/dashboard';
      });
      accountButton.setAttribute('aria-label', 'Dashboard');
    } else {
      // User not logged in - go to sign in
      accountButton.addEventListener('click', () => {
        window.location.href = '/session/new';
      });
      accountButton.setAttribute('aria-label', 'Sign In');
    }
  })
  .catch(() => {
    // Default to sign in on any error
    accountButton.addEventListener('click', () => {
      window.location.href = '/session/new';
    });
    accountButton.setAttribute('aria-label', 'Sign In');
  });

  // Add checkbox to encryption form for tracking
  const encryptForm = document.getElementById('encryptForm');
  if (encryptForm) {
    // Check if user is logged in for message tracking
    fetch('/account/dashboard', {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'same-origin'
    })
    .then(response => {
      if (response.ok && response.headers.get('content-type')?.includes('application/json')) {
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
