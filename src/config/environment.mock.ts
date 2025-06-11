/**
 * Mock environment for testing
 */
export class MockEnvironmentService {
  static getBaseUrl(): string {
    return 'http://localhost:5173';
  }

  static getApiUrl(): string {
    return 'http://localhost:3000/api/v1';
  }

  static isDevelopment(): boolean {
    return true;
  }

  static log(message: string, data?: any): void {
    console.log(`[TEST] ${message}`, data);
  }
}
