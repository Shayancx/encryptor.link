import React, { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { Lock, Upload, X, Timer, Eye, Flame, Copy } from "lucide-react"

export default function EncryptionPage() {
  const [message, setMessage] = useState("")
  const [usePassword, setUsePassword] = useState(false)
  const [password, setPassword] = useState("")
  const [burnAfterReading, setBurnAfterReading] = useState(false)
  const [encryptedLink, setEncryptedLink] = useState("")
  const [showResult, setShowResult] = useState(false)

  const handleEncrypt = async () => {
    // Basic validation
    if (!message.trim()) {
      alert("Please enter a message")
      return
    }

    // For now, just show a demo result
    setEncryptedLink(`${window.location.origin}/demo-id#demo-key`)
    setShowResult(true)
  }

  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(encryptedLink)
      alert("Link copied to clipboard!")
    } catch (error) {
      console.error("Failed to copy:", error)
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Lock className="h-5 w-5" />
            Create Encrypted Message
          </CardTitle>
          <CardDescription>
            Create a secure, self-destructing message or file share
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {/* Message Input */}
          <div className="space-y-2">
            <Label htmlFor="message">Message</Label>
            <Textarea
              id="message"
              placeholder="Enter your secret message here..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              className="min-h-[150px]"
            />
          </div>

          <Separator />

          {/* Security Options */}
          <div className="space-y-4">
            <h3 className="font-medium">Security Options</h3>
            
            {/* Password Protection */}
            <div className="flex items-center space-x-2">
              <Checkbox
                id="password"
                checked={usePassword}
                onCheckedChange={setUsePassword}
              />
              <Label htmlFor="password" className="flex items-center gap-2">
                <Lock className="h-4 w-4" />
                Require password
              </Label>
            </div>

            {usePassword && (
              <Input
                type="password"
                placeholder="Enter password..."
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            )}

            {/* Burn After Reading */}
            <div className="flex items-center space-x-2">
              <Checkbox
                id="burn"
                checked={burnAfterReading}
                onCheckedChange={setBurnAfterReading}
              />
              <Label htmlFor="burn" className="flex items-center gap-2">
                <Flame className="h-4 w-4" />
                Delete after first view
              </Label>
            </div>

            {burnAfterReading && (
              <Alert>
                <AlertDescription>
                  This setting overrides the view limit and TTL. The message will be permanently deleted immediately after the first view.
                </AlertDescription>
              </Alert>
            )}
          </div>

          {/* Encrypt Button */}
          <Button 
            onClick={handleEncrypt} 
            disabled={!message.trim()}
            className="w-full"
            size="lg"
          >
            <Lock className="h-4 w-4 mr-2" />
            Encrypt & Generate Link
          </Button>
        </CardContent>
      </Card>

      {/* Results */}
      {showResult && (
        <Card>
          <CardHeader>
            <CardTitle className="text-green-600">Your encrypted link has been generated</CardTitle>
            <CardDescription>
              {usePassword 
                ? "This link requires a password to access. Share both the link and password separately for maximum security."
                : "This link contains the decryption key. Anyone with this link can view your message or download your files."
              }
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex gap-2">
              <Input value={encryptedLink} readOnly />
              <Button onClick={copyToClipboard} variant="outline">
                <Copy className="h-4 w-4" />
              </Button>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  )
}
