import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.originalFetch = window.fetch;
    window.fetch = async (...args) => {
      const response = await this.originalFetch(...args);
      if (response.status === 429) {
        const retryAfter = response.headers.get('Retry-After') || 60;
        this.showRateLimitError(retryAfter);
      }
      return response;
    };
  }

  disconnect() {
    if (this.originalFetch) {
      window.fetch = this.originalFetch;
    }
  }

  showRateLimitError(retryAfter) {
    const alert = document.createElement('div');
    alert.className = 'alert alert-danger';
    alert.role = 'alert';
    alert.innerHTML = `
      <h4 class="alert-heading">Rate limit exceeded</h4>
      <p>You've made too many requests. Please try again after ${retryAfter} seconds.</p>
    `;
    document.body.insertBefore(alert, document.body.firstChild);
    setTimeout(() => alert.remove(), 5000);
  }
}
