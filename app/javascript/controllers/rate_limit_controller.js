import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Add event listeners for fetch errors
    this.addFetchErrorHandling();
  }

  addFetchErrorHandling() {
    // Store the original fetch function
    const originalFetch = window.fetch;
    
    // Replace with our custom function
    window.fetch = async (...args) => {
      try {
        const response = await originalFetch(...args);
        
        // Handle rate limiting response
        if (response.status === 429) {
          const retryAfter = response.headers.get('Retry-After') || 60;
          this.showRateLimitError(retryAfter);
        }
        
        return response;
      } catch (error) {
        throw error;
      }
    };
  }
  
  showRateLimitError(retryAfter) {
    // Create alert element
    const alert = document.createElement('div');
    alert.className = 'alert alert-danger';
    alert.role = 'alert';
    alert.innerHTML = `
      <h4 class="alert-heading">Rate limit exceeded</h4>
      <p>You've made too many requests. Please try again after ${retryAfter} seconds.</p>
    `;
    
    // Add to page and remove after delay
    document.body.insertBefore(alert, document.body.firstChild);
    
    setTimeout(() => {
      alert.remove();
    }, 5000);
  }
}
