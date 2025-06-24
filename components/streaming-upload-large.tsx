"use client"

import { useState, useRef } from "react"
import { Upload, X, AlertCircle } from "lucide-react"
import { streamEncryptAndUpload } from "@/lib/streaming-crypto"
import { Button } from "@/components/ui/button"
import { Progress } from "@/components/ui/progress"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { useToast } from "@/components/ui/use-toast"

interface StreamingUploadLargeProps {
  onComplete: (fileId: string, shareableLink: string) => void
  password: string
  authToken?: string
  uploadLimitMB: number
}

export function StreamingUploadLarge({ 
  onComplete,
  password, 
  authToken, 
  uploadLimitMB
}: StreamingUploadLargeProps) {
  const [isUploading, setIsUploading] = useState(false)
  const [progress, setProgress] = useState(0)
  const [selectedFile, setSelectedFile] = useState<File | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { toast } = useToast()
  const abortController = useRef<AbortController | null>(null)

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    const limitBytes = uploadLimitMB * 1024 * 1024
    if (file.size > limitBytes) {
      toast({
        title: "File too large",
        description: `File exceeds ${uploadLimitMB}MB limit`,
        variant: "destructive"
      })
      return
    }

    setSelectedFile(file)
  }

  const handleUpload = async () => {
    if (!selectedFile || !password) return

    setIsUploading(true)
    setProgress(0)
    abortController.current = new AbortController()

    try {
      const result = await streamEncryptAndUpload(
        selectedFile,
        password,
        authToken,
        (p) => setProgress(p),
        abortController.current.signal
      )

      onComplete(result.fileId, result.shareableLink)
      
      toast({
        title: "Upload complete",
        description: "Large file uploaded successfully"
      })
    } catch (error: any) {
      if (error.message !== 'Upload cancelled') {
        toast({
          title: "Upload failed",
          description: error.message,
          variant: "destructive"
        })
      }
    } finally {
      setIsUploading(false)
      setProgress(0)
      setSelectedFile(null)
      abortController.current = null
    }
  }

  const cancelUpload = () => {
    if (abortController.current) {
      abortController.current.abort()
    }
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle>Large File Upload</CardTitle>
        <CardDescription>
          For files over 50MB, use this streaming upload
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <input
          ref={fileInputRef}
          type="file"
          className="hidden"
          onChange={handleFileSelect}
          disabled={isUploading}
        />
        
        {!selectedFile && !isUploading && (
          <Button
            onClick={() => fileInputRef.current?.click()}
            className="w-full"
          >
            <Upload className="mr-2 h-4 w-4" />
            Select Large File
          </Button>
        )}

        {selectedFile && !isUploading && (
          <div className="space-y-4">
            <div className="rounded-lg border p-4">
              <p className="font-medium">{selectedFile.name}</p>
              <p className="text-sm text-muted-foreground">
                {(selectedFile.size / 1024 / 1024).toFixed(2)} MB
              </p>
            </div>
            <div className="flex gap-2">
              <Button onClick={handleUpload} className="flex-1">
                Upload
              </Button>
              <Button 
                onClick={() => setSelectedFile(null)} 
                variant="outline"
              >
                Cancel
              </Button>
            </div>
          </div>
        )}

        {isUploading && (
          <div className="space-y-4">
            <div className="space-y-2">
              <div className="flex justify-between text-sm">
                <span>Uploading {selectedFile?.name}...</span>
                <span>{Math.round(progress)}%</span>
              </div>
              <Progress value={progress} />
            </div>
            <Button 
              onClick={cancelUpload} 
              variant="destructive" 
              className="w-full"
            >
              <X className="mr-2 h-4 w-4" />
              Cancel Upload
            </Button>
          </div>
        )}

        <Alert>
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>
            Large files are encrypted and uploaded in chunks to prevent browser crashes.
            This process may take several minutes for very large files.
          </AlertDescription>
        </Alert>
      </CardContent>
    </Card>
  )
}
