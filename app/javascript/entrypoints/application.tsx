import React from "react"
import ReactDOM from "react-dom/client"
import App from "@/components/App"
import "@/entrypoints/application.css"

// Initialize Stimulus for any remaining legacy controllers
import { Application } from "@hotwired/stimulus"
import ThemeController from "@/controllers/theme_controller"
import RateLimitController from "@/controllers/rate_limit_controller"
import "@/lib/csrf-helper"

declare global {
  interface Window {
    Stimulus: Application
  }
}

window.Stimulus = Application.start()
window.Stimulus.register("theme", ThemeController)
window.Stimulus.register("rate-limit", RateLimitController)

// Mount React app
const rootElement = document.getElementById("react-root")
if (rootElement) {
  ReactDOM.createRoot(rootElement).render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  )
} else {
  console.error("React root element not found")
}
