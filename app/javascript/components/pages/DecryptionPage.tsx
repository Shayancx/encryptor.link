import React, { useState, useEffect } from "react"
import { useParams } from "react-router-dom"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { Lock, Download, Copy, AlertTriangle, CheckCircle } from "lucide-react"

export default function DecryptionPage() {
  const { id } = useParams<{ id: string }>()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [decryptedMessage, setDecryptedMessage] = useState("")
  const [showContent, setShowContent] = useState(false)

  useEffect(() => {
    // Simulate loading and decryption
    setTimeout(() => {
      if (id === "demo-id") {
        setDecryptedMessage("This is your decrypted message! 🎉")
        setShowContent(true)
      } else {
        setError("This message has expired or does not exist.")
      }
      setLoading(false)
    }, 1000)
  }, [id])

  const copyMessage = async () => {
    try {
      await navigator.clipboard.writeText(decryptedMessage)
      alert("Message copied to clipboard!")
    } catch (err) {
      console.error("Failed to copy message:", err)
    }
  }

  if (loading) {
    return (
      <Card>
        <CardContent className="p-6">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4" />
            <p>Fetching encrypted data...</p>
          </div>
        </CardContent>
      </Card>
    )
  }

  if (error) {
    return (
      <Card>
        <CardContent className="p-6">
          <Alert variant="destructive">
            <AlertTriangle className="h-4 w-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    )
  }

  if (showContent) {
    return (
      <div className="space-y-6">
        <Alert>
          <CheckCircle className="h-4 w-4" />
          <AlertDescription>
            <strong>One-time message!</strong> This message has been decrypted in your browser and cannot be accessed again.
          </AlertDescription>
        </Alert>

        <Card>
          <CardHeader>
            <CardTitle>Decrypted Message</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="prose prose-sm max-w-none p-4 bg-muted rounded-lg">
              <pre className="whitespace-pre-wrap font-sans">{decryptedMessage}</pre>
            </div>
            <Button onClick={copyMessage} variant="outline">
              <Copy className="h-4 w-4 mr-2" />
              Copy Message
            </Button>
          </CardContent>
        </Card>

        <div className="text-center">
          <Button asChild>
            <a href="/">Create Your Own Encrypted Message</a>
          </Button>
        </div>
      </div>
    )
  }

  return null
}
