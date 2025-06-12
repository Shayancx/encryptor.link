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
    return 'https://encryptor.link';
  }

  static getApiUrl(): string {
    if (this.env === 'development') {
      return 'http://localhost:3000/api/v1';
    }
    return 'https://encryptor.link/api/v1';
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
    return `${this.getBaseUrl()}${path}`;
  }

  static getApiEndpoint(path: string): string {
    return `${this.getApiUrl()}${path}`;
  }

  static log(message: string, data?: any): void {
    if (this.isDevelopment()) {
      if (data) {
        console.log(`[${this.env.toUpperCase()}] ${message}`, data);
      } else {
        console.log(`[${this.env.toUpperCase()}] ${message}`);
      }
    }
  }
}
