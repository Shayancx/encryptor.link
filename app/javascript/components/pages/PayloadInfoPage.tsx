import React, { useState } from "react"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Search } from "lucide-react"

export default function PayloadInfoPage() {
  const [link, setLink] = useState("")
  const [loading, setLoading] = useState(false)

  const checkStatus = async () => {
    if (!link.trim()) return

    setLoading(true)
    // Simulate checking
    setTimeout(() => {
      alert("Link status check functionality coming soon!")
      setLoading(false)
    }, 1000)
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Search className="h-5 w-5" />
            Check Link Status
          </CardTitle>
          <CardDescription>
            Check the status and details of an encrypted link
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="link">Paste encrypted link</Label>
            <Input
              id="link"
              placeholder="https://encryptor.link/abcd1234"
              value={link}
              onChange={(e) => setLink(e.target.value)}
            />
          </div>
          <Button onClick={checkStatus} disabled={loading || !link.trim()}>
            {loading ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                Checking...
              </>
            ) : (
              <>
                <Search className="h-4 w-4 mr-2" />
                Check Status
              </>
            )}
          </Button>
        </CardContent>
      </Card>
    </div>
  )
}
