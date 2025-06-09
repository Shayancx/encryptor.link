export interface ErrorDetails {
  code?: string;
  field?: string;
  context?: any;
}

export class ErrorService {
  private static errorHandlers: ((error: Error, details?: ErrorDetails) => void)[] = [];

  static handle(error: Error | string, details?: ErrorDetails): void {
    const errorObj = typeof error === 'string' ? new Error(error) : error;
    
    console.error('Error:', errorObj, details);
    
    // Run registered error handlers
    this.errorHandlers.forEach(handler => {
      try {
        handler(errorObj, details);
      } catch (handlerError) {
        console.error('Error handler failed:', handlerError);
      }
    });

    // Default UI feedback
    this.showUserError(errorObj.message);
  }

  static showUserError(message: string): void {
    // For now, use alert. In production, use a toast/notification system
    alert(`Error: ${message}`);
  }

  static registerErrorHandler(handler: (error: Error, details?: ErrorDetails) => void): void {
    this.errorHandlers.push(handler);
  }

  static unregisterErrorHandler(handler: (error: Error, details?: ErrorDetails) => void): void {
    const index = this.errorHandlers.indexOf(handler);
    if (index !== -1) {
      this.errorHandlers.splice(index, 1);
    }
  }

  static isNetworkError(error: Error): boolean {
    return error.name === 'NetworkError' || 
           error.message.toLowerCase().includes('network') ||
           error.message.toLowerCase().includes('fetch');
  }

  static isAbortError(error: Error): boolean {
    return error.name === 'AbortError';
  }
}

export default ErrorService;
