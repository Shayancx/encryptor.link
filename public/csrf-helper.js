// CSRF Token Helper
class CSRFHelper {
  static getToken() {
    const tokenElement = document.querySelector('meta[name="csrf-token"]');
    return tokenElement ? tokenElement.getAttribute('content') : null;
  }

  static getHeaders(additionalHeaders = {}) {
    const token = this.getToken();
    const headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...additionalHeaders
    };

    if (token) {
      headers['X-CSRF-Token'] = token;
    }

    return headers;
  }

  static async fetchWithCSRF(url, options = {}) {
    const defaultOptions = {
      headers: this.getHeaders(options.headers || {})
    };

    const mergedOptions = {
      ...defaultOptions,
      ...options,
      headers: {
        ...defaultOptions.headers,
        ...(options.headers || {})
      }
    };

    return fetch(url, mergedOptions);
  }
}

// Make it available globally
window.CSRFHelper = CSRFHelper;

// Export for modules
if (typeof module !== 'undefined' && module.exports) {
  module.exports = CSRFHelper;
}
