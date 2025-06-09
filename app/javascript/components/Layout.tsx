import React from "react"
import { Button } from "@/components/ui/button"
import { useTheme } from "@/components/theme-provider"
import { Sun, Moon } from "lucide-react"

interface LayoutProps {
  children: React.ReactNode
}

export default function Layout({ children }: LayoutProps) {
  const { theme, setTheme } = useTheme()

  const toggleTheme = () => {
    setTheme(theme === "dark" ? "light" : "dark")
  }

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="bg-gray-800 text-white border-b sticky top-0 z-50">
        <div className="max-w-4xl mx-auto flex items-center justify-between gap-4 p-4">
          <a href="/" className="text-xl font-semibold hover:text-gray-300 transition-colors">
            encryptor.link
          </a>
          <a 
            href="/check" 
            className="text-sm text-gray-400 hover:text-white transition-colors"
          >
            Check Link Status
          </a>
          <Button
            variant="ghost"
            size="icon"
            onClick={toggleTheme}
            className="text-white hover:bg-gray-700"
          >
            {theme === "dark" ? (
              <Sun className="h-5 w-5" />
            ) : (
              <Moon className="h-5 w-5" />
            )}
          </Button>
        </div>
      </header>

      <main className="max-w-4xl mx-auto p-4">
        {children}
      </main>

      <footer className="border-t py-4 text-center text-xs text-muted-foreground">
        <p>Zero-knowledge, client-side encrypted messages</p>
        <p>All encryption and decryption happens in your browser. The server never sees your plaintext data.</p>
      </footer>
    </div>
  )
}
