export class ErrorBoundary {
  static async wrap<T>(
    operation: () => Promise<T>,
    fallback?: T
  ): Promise<T | undefined> {
    try {
      return await operation();
    } catch (error) {
      console.error('Operation failed:', error);
      if (fallback !== undefined) {
        return fallback;
      }
      return undefined;
    }
  }

  static wrapSync<T>(
    operation: () => T,
    fallback?: T
  ): T | undefined {
    try {
      return operation();
    } catch (error) {
      console.error('Operation failed:', error);
      if (fallback !== undefined) {
        return fallback;
      }
      return undefined;
    }
  }

  static async wrapWithRetry<T>(
    operation: () => Promise<T>,
    maxRetries: number = 3,
    delay: number = 1000
  ): Promise<T> {
    let lastError: Error | undefined;
    
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error as Error;
        if (i < maxRetries - 1) {
          await new Promise(resolve => setTimeout(resolve, delay * (i + 1)));
        }
      }
    }
    
    throw lastError || new Error('Operation failed after retries');
  }
}
