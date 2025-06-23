// Enhanced logging for streaming uploads
export class StreamingLogger {
  private static enabled = typeof window !== 'undefined' && 
    (localStorage.getItem('debug_streaming') === 'true' || 
     new URLSearchParams(window.location.search).has('debug'));

  static log(context: string, message: string, data?: any) {
    if (!this.enabled) return;
    
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] [${context}] ${message}`;
    
    console.log(`%c${logEntry}`, 'color: #3b82f6; font-weight: bold;', data || '');
    
    // Store in session storage for debugging
    const logs = JSON.parse(sessionStorage.getItem('streaming_logs') || '[]');
    logs.push({ timestamp, context, message, data });
    if (logs.length > 1000) logs.shift(); // Keep last 1000 entries
    sessionStorage.setItem('streaming_logs', JSON.stringify(logs));
  }

  static error(context: string, message: string, error: any) {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] [${context}] ERROR: ${message}`;
    
    console.error(`%c${logEntry}`, 'color: #ef4444; font-weight: bold;', error);
    
    // Always log errors
    const logs = JSON.parse(sessionStorage.getItem('streaming_errors') || '[]');
    logs.push({ timestamp, context, message, error: error?.message || error });
    if (logs.length > 100) logs.shift();
    sessionStorage.setItem('streaming_errors', JSON.stringify(logs));
  }

  static getLogDump() {
    return {
      logs: JSON.parse(sessionStorage.getItem('streaming_logs') || '[]'),
      errors: JSON.parse(sessionStorage.getItem('streaming_errors') || '[]')
    };
  }

  static clearLogs() {
    sessionStorage.removeItem('streaming_logs');
    sessionStorage.removeItem('streaming_errors');
  }
}

// Export function to enable debugging
export function enableStreamingDebug() {
  localStorage.setItem('debug_streaming', 'true');
  console.log('🔧 Streaming debug mode enabled. Reload to see logs.');
}

// Attach to window for easy access
if (typeof window !== 'undefined') {
  (window as any).streamingDebug = {
    enable: () => enableStreamingDebug(),
    disable: () => localStorage.removeItem('debug_streaming'),
    dump: () => StreamingLogger.getLogDump(),
    clear: () => StreamingLogger.clearLogs()
  };
}
