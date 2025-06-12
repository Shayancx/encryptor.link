type Environment = 'development' | 'test' | 'production';

export class EnvironmentService {
  private static env: Environment = 
    process.env.NODE_ENV === 'production' ? 'production' :
    process.env.NODE_ENV === 'test' ? 'test' : 
    'development';

  static getBaseUrl(): string {
    if (this.env === 'development') {
      return 'http://localhost:5173';
    }
    // In production, use relative URLs
    return '';
  }

  static getApiUrl(): string {
    // Always use relative URLs for API
    return '/api/v1';
  }

  static getEnvironment(): Environment {
    return this.env;
  }

  static isDevelopment(): boolean {
    return this.env === 'development';
  }

  static isProduction(): boolean {
    return this.env === 'production';
  }

  static getUrl(path: string): string {
    const base = this.getBaseUrl();
    return base ? `${base}${path}` : path;
  }

  static getApiEndpoint(path: string): string {
    return `${this.getApiUrl()}${path}`;
  }

  static log(message: string, data?: any): void {
    if (this.isDevelopment()) {
      if (data !== undefined) {
        console.log(`[${this.env.toUpperCase()}] ${message}`, data);
      } else {
        console.log(`[${this.env.toUpperCase()}] ${message}`);
      }
    }
  }
}
