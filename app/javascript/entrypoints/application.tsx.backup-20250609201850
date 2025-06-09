import React from 'react'
import { createRoot } from 'react-dom/client'
import App from '../components/App'
import './application.css'

console.log('🚀 Starting React application...')

// Wait for DOM to be ready
function mountApp() {
  const rootElement = document.getElementById('react-root')
  
  if (!rootElement) {
    console.error('❌ Could not find root element!')
    return
  }
  
  console.log('✅ Mounting React app...')
  
  try {
    const root = createRoot(rootElement)
    root.render(
      <React.StrictMode>
        <App />
      </React.StrictMode>
    )
    console.log('✅ React app mounted successfully!')
  } catch (error) {
    console.error('❌ Error mounting React app:', error)
  }
}

// Mount when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', mountApp)
} else {
  mountApp()
}
