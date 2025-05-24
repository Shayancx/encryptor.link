// Simple rate limit handler
(function() {
  const originalFetch = window.fetch;

  window.fetch = async function(...args) {
    try {
      const response = await originalFetch(...args);

      if (response.status === 429) {
        const retryAfter = response.headers.get('Retry-After') || 60;
        showRateLimitError(retryAfter);
      }

      return response;
    } catch (error) {
      throw error;
    }
  };

  function showRateLimitError(retryAfter) {
    const alert = document.createElement('div');
    alert.className = 'alert alert-danger';
    alert.role = 'alert';
    alert.innerHTML = `
      <h4 class="alert-heading">Rate limit exceeded</h4>
      <p>You've made too many requests. Please try again after ${retryAfter} seconds.</p>
    `;

    document.body.insertBefore(alert, document.body.firstChild);

    setTimeout(() => {
      alert.remove();
    }, 5000);
  }
})();
