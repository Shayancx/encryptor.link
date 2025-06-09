import React from "react"
import { BrowserRouter as Router, Routes, Route, Navigate } from "react-router-dom"
import EncryptionPage from "@/components/pages/EncryptionPage"
import DecryptionPage from "@/components/pages/DecryptionPage"
import PayloadInfoPage from "@/components/pages/PayloadInfoPage"
import Layout from "@/components/Layout"
import { ThemeProvider } from "@/components/theme-provider"

export default function App() {
  return (
    <ThemeProvider defaultTheme="dark" storageKey="encryptor-theme">
      <Router>
        <Layout>
          <Routes>
            <Route path="/" element={<EncryptionPage />} />
            <Route path="/check" element={<PayloadInfoPage />} />
            <Route path="/:id" element={<DecryptionPage />} />
            {/* Redirect any other paths to home */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </Layout>
      </Router>
    </ThemeProvider>
  )
}
