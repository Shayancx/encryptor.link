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

  // Check if user is logged in using the dedicated auth status endpoint
  fetch('/auth/status', {
    headers: {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest'
    },
    credentials: 'same-origin'
  })
  .then(response => {
    if (!response.ok) {
      throw new Error('Auth check failed');
    }
    return response.json();
  })
  .then(data => {
    if (data.authenticated) {
      // User is logged in - go to dashboard
      accountButton.addEventListener('click', () => {
        window.location.href = '/account/dashboard';
      });
      accountButton.setAttribute('aria-label', 'Dashboard');

      // Add visual indicator that user is logged in
      accountButton.classList.add('authenticated');
    } else {
      // User not logged in - go to sign in
      accountButton.addEventListener('click', () => {
        window.location.href = '/session/new';
      });
      accountButton.setAttribute('aria-label', 'Sign In');
    }
  })
  .catch((error) => {
    console.error('Error checking auth status:', error);
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
    fetch('/auth/status', {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      },
      credentials: 'same-origin'
    })
    .then(response => {
      if (!response.ok) return { authenticated: false };
      return response.json();
    })
    .then(data => {
      if (data.authenticated) {
        // Add tracking options
        const trackingDiv = document.createElement('div');
        trackingDiv.className = 'mb-3';
        trackingDiv.innerHTML = `
          <div class="form-check mb-2">
            <input class="form-check-input" type="checkbox" id="trackMessage" checked>
            <label class="form-check-label" for="trackMessage">
              Save to my message history
            </label>
          </div>
          <div id="trackingOptions" class="ps-4">
            <div class="mb-2">
              <label for="messageLabel" class="form-label small">Label (optional):</label>
              <input type="text" class="form-control form-control-sm" id="messageLabel" placeholder="e.g., Contract for John">
            </div>
          </div>
        `;

        const submitBtn = encryptForm.querySelector('button[type="submit"]');
        submitBtn.parentNode.insertBefore(trackingDiv, submitBtn);

        // Toggle tracking options
        document.getElementById('trackMessage').addEventListener('change', function() {
          document.getElementById('trackingOptions').style.display = this.checked ? 'block' : 'none';
        });
      }
    })
    .catch(() => {
      // Not logged in, no tracking option
    });
  }
});
