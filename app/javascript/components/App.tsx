import React from 'react'
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom'
import Layout from './Layout'
import EncryptionPage from './pages/EncryptionPage'
import DecryptionPage from './pages/DecryptionPage'
import PayloadInfoPage from './pages/PayloadInfoPage'
import { ThemeProvider } from './theme-provider'

export default function App() {
  return (
    <ThemeProvider defaultTheme="system" storageKey="vite-ui-theme">
      <Router>
        <Layout>
          <Routes>
            <Route path="/" element={<EncryptionPage />} />
            <Route path="/check" element={<PayloadInfoPage />} />
            <Route path="/:id" element={<DecryptionPage />} />
          </Routes>
        </Layout>
      </Router>
    </ThemeProvider>
  )
}
