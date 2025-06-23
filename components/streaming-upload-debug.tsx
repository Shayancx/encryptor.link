import { StreamingUpload } from './streaming-upload'

// Enable debug mode by setting localStorage
if (typeof window !== 'undefined') {
  // To enable debug mode, run in console: localStorage.setItem('debug_streaming', 'true')
  const debugMode = localStorage.getItem('debug_streaming') === 'true'
  
  if (debugMode) {
    console.log('🔧 Streaming Upload Debug Mode Enabled')
    
    // Override console methods to add timestamps
    const originalLog = console.log
    const originalError = console.error
    const originalWarn = console.warn
    
    console.log = (...args: any[]) => {
      originalLog(`[${new Date().toISOString()}]`, ...args)
    }
    
    console.error = (...args: any[]) => {
      originalError(`[${new Date().toISOString()}] ERROR:`, ...args)
    }
    
    console.warn = (...args: any[]) => {
      originalWarn(`[${new Date().toISOString()}] WARN:`, ...args)
    }
  }
}

export { StreamingUpload }
