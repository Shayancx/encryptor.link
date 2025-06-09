import React from "react"

export default function App() {
  console.log("🎨 App component rendering...")
  
  return (
    <div style={{ 
      padding: "20px", 
      color: "white", 
      backgroundColor: "#1a1a1a", 
      minHeight: "100vh",
      fontFamily: "system-ui, sans-serif"
    }}>
      <h1 style={{ color: "#4ade80", marginBottom: "20px" }}>
        🎉 React + Vite is working!
      </h1>
      <p style={{ marginBottom: "20px" }}>
        If you can see this, React is mounted successfully and Vite is serving the assets properly.
      </p>
      <div style={{ 
        marginTop: "20px", 
        padding: "20px", 
        border: "1px solid #333", 
        borderRadius: "8px",
        backgroundColor: "#2a2a2a"
      }}>
        <h2 style={{ color: "#60a5fa", marginBottom: "15px" }}>Debug Info:</h2>
        <div style={{ fontFamily: "monospace", fontSize: "14px" }}>
          <p>• React: ✅ Loaded and rendering</p>
          <p>• Vite: ✅ Serving modules properly</p>
          <p>• CSP: ✅ Allowing necessary connections</p>
          <p>• Ready for: shadcn/ui components</p>
        </div>
      </div>
      <div style={{ marginTop: "20px", fontSize: "14px", opacity: 0.7 }}>
        <p>Next steps: Add router and shadcn/ui components</p>
      </div>
    </div>
  )
}
