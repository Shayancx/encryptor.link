// CSRF Token Helper
export default class CSRFHelper {
  static getToken(): string | null {
    const tokenElement = document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]');
    return tokenElement ? tokenElement.getAttribute('content') : null;
  }

  static getHeaders(additionalHeaders: Record<string, string> = {}): Record<string, string> {
    const token = this.getToken();
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...additionalHeaders
    };

    if (token) {
      headers['X-CSRF-Token'] = token;
    }

    return headers;
  }

  static async fetchWithCSRF(url: string, options: RequestInit = {}): Promise<Response> {
    const defaultOptions: RequestInit = {
      headers: this.getHeaders((options.headers || {}) as Record<string, string>),
      credentials: 'same-origin'
    };

    const mergedOptions: RequestInit = {
      ...defaultOptions,
      ...options,
      headers: {
        ...(defaultOptions.headers as Record<string, string>),
        ...(options.headers || {})
      },
      credentials: options.credentials || defaultOptions.credentials
    };

    return fetch(url, mergedOptions);
  }
}

// Make it available globally
if (typeof window !== 'undefined') {
  (window as any).CSRFHelper = CSRFHelper;
}
