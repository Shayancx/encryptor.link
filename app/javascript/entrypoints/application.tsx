import React from "react"
import ReactDOM from "react-dom/client"
import App from "../components/App"

console.log("🚀 Starting React app...")

// Find the root element
const rootElement = document.getElementById("react-root")
console.log("Root element found:", !!rootElement)

if (rootElement) {
  console.log("✅ Mounting React app...")
  try {
    const root = ReactDOM.createRoot(rootElement)
    root.render(
      <React.StrictMode>
        <App />
      </React.StrictMode>
    )
    console.log("✅ React app mounted successfully!")
  } catch (error) {
    console.error("❌ Error mounting React app:", error)
  }
} else {
  console.error("❌ React root element not found!")
  document.body.innerHTML = `
    <div style="padding: 20px; background: #fee; color: #900; font-family: monospace;">
      <h1>❌ React Mount Error</h1>
      <p>Could not find element with ID 'react-root'</p>
      <p>Check the HTML layout file.</p>
    </div>
  `
}
