import { BaseController } from "./base/BaseController";

export default class extends BaseController {
  private originalFetch: typeof window.fetch | null = null;

  connect(): void {
    this.originalFetch = window.fetch.bind(window);
    window.fetch = this.interceptedFetch.bind(this);
  }

  disconnect(): void {
    if (this.originalFetch) {
      window.fetch = this.originalFetch;
    }
    super.disconnect();
  }

  private async interceptedFetch(...args: Parameters<typeof fetch>): Promise<Response> {
    if (!this.originalFetch) {
      throw new Error('Original fetch not available');
    }

    const response = await this.originalFetch(...args);
    
    if (response.status === 429) {
      const retryAfter = response.headers.get('Retry-After') || '60';
      this.showRateLimitError(retryAfter);
    }
    
    return response;
  }

  private showRateLimitError(retryAfter: string): void {
    // Check if alert already exists
    if (document.querySelector('.rate-limit-alert')) {
      return;
    }

    const alert = document.createElement('div');
    alert.className = 'alert alert-danger rate-limit-alert';
    alert.role = 'alert';
    alert.innerHTML = `
      <h4 class="alert-heading">Rate limit exceeded</h4>
      <p>You've made too many requests. Please try again after ${retryAfter} seconds.</p>
    `;
    
    document.body.insertBefore(alert, document.body.firstChild);
    
    // Auto-remove after 5 seconds
    setTimeout(() => alert.remove(), 5000);
  }
}
