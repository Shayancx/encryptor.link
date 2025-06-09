// Main entry point for the application
import React from 'react';
import { createRoot } from 'react-dom/client';
import App from '../components/App';

// Import your styles
import '../stylesheets/application.css';

// Mount the React application
document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('root');
  if (container) {
    const root = createRoot(container);
    root.render(React.createElement(App));
  }
});
