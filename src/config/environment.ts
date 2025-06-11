/**
 * Environment configuration service
 * Handles environment-specific settings and provides helper methods
 */

// Environment types
type Environment = 'development' | 'test' | 'production';

export class EnvironmentService {
  // Current environment
  private static env: Environment = 
    process.env.NODE_ENV === 'production' ? 'production' :
    process.env.NODE_ENV === 'test' ? 'test' : 
    'development';

  // Base URL depending on environment
  static getBaseUrl(): string {
    if (this.env === 'development') {
      return 'http://localhost:5173';
    }
    
    return this.env === 'production' ? 'https://encryptor.link' : 'http://localhost:5173';
  }

  // API URL depending on environment
  static getApiUrl(): string {
    // Always point to Rails server for API in development
    if (this.env === 'development') {
      return 'http://localhost:3000/api/v1';
    }
    
    return this.env === 'production' ? 'https://encryptor.link/api/v1' : 'http://localhost:3000/api/v1';
  }

  /**
   * Get current environment
   */
  static getEnvironment(): Environment {
    return this.env;
  }

  /**
   * Check if environment is development
   */
  static isDevelopment(): boolean {
    return this.env === 'development';
  }

  /**
   * Check if environment is production
   */
  static isProduction(): boolean {
    return this.env === 'production';
  }

  /**
   * Get absolute URL with path
   */
  static getUrl(path: string): string {
    return `${this.getBaseUrl()}${path}`;
  }

  /**
   * Get API URL with path
   */
  static getApiEndpoint(path: string): string {
    return `${this.getApiUrl()}${path}`;
  }

  /**
   * Log message based on environment
   */
  static log(message: string, data?: any): void {
    if (this.isDevelopment() || this.env === 'test') {
      if (data) {
        console.log(`[${this.env.toUpperCase()}] ${message}`, data);
      } else {
        console.log(`[${this.env.toUpperCase()}] ${message}`);
      }
    }
  }
}
