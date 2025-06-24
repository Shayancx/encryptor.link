"use client"

import { useState, useRef } from "react"
import { Copy, FileText, Lock, Upload, X, AlertCircle } from "lucide-react"
import Link from "next/link"

import { encrypt } from "@/lib/crypto"
import { safeBase64Encode } from "@/lib/base64-utils"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { useToast } from "@/components/ui/use-toast"
import { TiptapEditor } from "@/components/editor/tiptap-editor"
import { useAuth } from "@/lib/contexts/auth-context"
import { Progress } from "@/components/ui/progress"
import { formatBytes } from "@/lib/utils"

interface FileToEncrypt {
  file: File
  id: string
}

export default function EncryptPage() {
  const [message, setMessage] = useState("")
  const [password, setPassword] = useState("")
  const [shareableLink, setShareableLink] = useState("")
  const [isEncrypting, setIsEncrypting] = useState(false)
  const [uploadProgress, setUploadProgress] = useState(0)
  const [filesToEncrypt, setFilesToEncrypt] = useState<FileToEncrypt[]>([])
  const [isDragging, setIsDragging] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { toast } = useToast()
  const { user } = useAuth()
  
  // Dynamic upload limits based on authentication
  const uploadLimitMB = user ? 4096 : 100
  const uploadLimitBytes = uploadLimitMB * 1024 * 1024
  const authToken = typeof window !== 'undefined' ? localStorage.getItem('auth_token') : null

  const validatePassword = (pwd: string) => {
    if (pwd.length < 8) return "Password must be at least 8 characters"
    if (!/[A-Z]/.test(pwd)) return "Password must contain uppercase letter"
    if (!/[a-z]/.test(pwd)) return "Password must contain lowercase letter"
    if (!/\d/.test(pwd)) return "Password must contain a number"
    return null
  }

  const handleFiles = (files: FileList) => {
    const newFiles: FileToEncrypt[] = []
    let totalSize = Array.from(filesToEncrypt).reduce((acc, f) => acc + f.file.size, 0)

    for (const file of Array.from(files)) {
      if (totalSize + file.size > uploadLimitBytes) {
        toast({
          title: "Files too large",
          description: `Total size exceeds ${uploadLimitMB}MB limit`,
          variant: "destructive"
        })
        break
      }
      totalSize += file.size
      newFiles.push({
        file,
        id: Math.random().toString(36).substr(2, 9)
      })
    }

    setFilesToEncrypt(prev => [...prev, ...newFiles])
  }

  const removeFile = (id: string) => {
    setFilesToEncrypt(prev => prev.filter(f => f.id !== id))
  }

  const handleEncryptAll = async () => {
    const passwordError = validatePassword(password)
    if (passwordError) {
      toast({
        title: "Weak password",
        description: passwordError,
        variant: "destructive"
      })
      return
    }

    if (!message && filesToEncrypt.length === 0) {
      toast({
        title: "Nothing to encrypt",
        description: "Please enter a message or add files",
        variant: "destructive"
      })
      return
    }

    setIsEncrypting(true)
    setUploadProgress(0)

    try {
      const encryptedData: any = {}
      
      // Encrypt message if present
      if (message) {
        setUploadProgress(10)
        const encryptedMessage = await encrypt(message, password, 'text')
        encryptedData.message = {
          ciphertext: encryptedMessage.ciphertext,
          iv: encryptedMessage.iv,
          salt: encryptedMessage.salt,
          isHtml: true
        }
      }

      // Encrypt files if present
      if (filesToEncrypt.length > 0) {
        encryptedData.files = []
        const progressPerFile = (message ? 80 : 90) / filesToEncrypt.length
        let currentProgress = message ? 10 : 0

        for (const fileItem of filesToEncrypt) {
          const file = fileItem.file
          currentProgress += progressPerFile / 2
          setUploadProgress(Math.round(currentProgress))

          // Read file
          const arrayBuffer = await file.arrayBuffer()
          
          // Encrypt file
          const encryptedFile = await encrypt(arrayBuffer, password, 'file', file.name)
          
          encryptedData.files.push({
            filename: file.name,
            mimetype: file.type || 'application/octet-stream',
            ciphertext: encryptedFile.ciphertext,
            iv: encryptedFile.iv,
            salt: encryptedFile.salt
          })

          currentProgress += progressPerFile / 2
          setUploadProgress(Math.round(currentProgress))
        }
      }

      setUploadProgress(90)

      // Prepare upload data
      const jsonString = JSON.stringify(encryptedData)
      const encodedData = safeBase64Encode(jsonString)
      
      // Check size after encoding
      const totalSize = encodedData.length
      if (totalSize > uploadLimitBytes) {
        throw new Error(`Combined encrypted data exceeds ${uploadLimitMB}MB limit`)
      }

      // Upload combined encrypted data
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
      }
      
      if (authToken) {
        headers['Authorization'] = `Bearer ${authToken}`
      }

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/upload`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          encrypted_data: encodedData,
          password: password,
          mime_type: 'application/json',
          filename: 'encrypted_data.json',
          iv: encryptedData.message?.iv || encryptedData.files?.[0]?.iv || '',
          ttl_hours: 24
        })
      })

      if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Upload failed' }))
        throw new Error(error.error || 'Upload failed')
      }

      const result = await response.json()
      const link = `${window.location.origin}/view/${result.file_id}`
      setShareableLink(link)
      setUploadProgress(100)

      toast({
        title: "Encryption successful",
        description: "Your data has been encrypted and uploaded"
      })
    } catch (error: any) {
      console.error('Encryption error:', error)
      toast({
        title: "Encryption failed",
        description: error.message,
        variant: "destructive"
      })
    } finally {
      setIsEncrypting(false)
      setUploadProgress(0)
    }
  }

  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(shareableLink)
      toast({
        title: "Copied to clipboard",
        description: "The shareable link has been copied"
      })
    } catch (error) {
      toast({
        title: "Copy failed",
        description: "Failed to copy to clipboard",
        variant: "destructive"
      })
    }
  }

  const reset = () => {
    setMessage("")
    setPassword("")
    setShareableLink("")
    setFilesToEncrypt([])
    setUploadProgress(0)
  }

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(false)
    
    if (e.dataTransfer.files.length > 0) {
      handleFiles(e.dataTransfer.files)
    }
  }

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault()
    setIsDragging(true)
  }

  const handleDragLeave = () => {
    setIsDragging(false)
  }

  const getTotalFileSize = () => {
    return filesToEncrypt.reduce((acc, f) => acc + f.file.size, 0)
  }

  return (
    <section className="container grid gap-6 pb-8 pt-6 md:py-10">
      <div className="flex flex-col items-center gap-2">
        <h1 className="text-3xl font-extrabold leading-tight tracking-tighter md:text-4xl">
          Encrypt Your Data
        </h1>
        <p className="max-w-[700px] text-center text-lg text-muted-foreground">
          Encrypt messages and files together in a single secure package.
          All encryption happens in your browser.
        </p>
      </div>

      <div className="mx-auto w-full max-w-4xl">
        {!shareableLink ? (
          <div className="space-y-6">
            {/* Upload Limit Notice */}
            {!user && (
              <Alert>
                <AlertDescription>
                  You're uploading as a guest ({uploadLimitMB}MB limit). 
                  <Link href="/register" className="font-medium underline ml-1">
                    Create an account
                  </Link> to upload up to 4GB.
                </AlertDescription>
              </Alert>
            )}

            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Lock className="size-5" />
                  Encryption Form
                </CardTitle>
                <CardDescription>
                  Add a message and/or files, then provide a strong password.
                  Everything will be encrypted together as one package.
                  {user && (
                    <span className="block mt-1 text-green-600 dark:text-green-400">
                      Authenticated user - {uploadLimitMB}MB upload limit
                    </span>
                  )}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Message Editor */}
                <div className="space-y-2">
                  <Label htmlFor="message">
                    <FileText className="mr-2 inline size-4" />
                    Message (Optional)
                  </Label>
                  <TiptapEditor
                    content={message}
                    onChange={setMessage}
                    placeholder="Enter your message here... You can format it using the toolbar above."
                  />
                </div>

                {/* Password Input */}
                <div className="space-y-2">
                  <Label htmlFor="password">
                    <Lock className="mr-2 inline size-4" />
                    Encryption Password (Required)
                  </Label>
                  <Input
                    id="password"
                    type="password"
                    placeholder="Min 8 chars, uppercase, lowercase, number..."
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                  />
                  <p className="text-xs text-muted-foreground">
                    Choose a strong password. Only a salted hash will be stored on the server.
                  </p>
                  {password && validatePassword(password) && (
                    <p className="text-xs text-destructive">{validatePassword(password)}</p>
                  )}
                </div>

                {/* File Upload */}
                <div className="space-y-2">
                  <Label>
                    <Upload className="mr-2 inline size-4" />
                    Files (Optional)
                  </Label>
                  
                  {/* Drop Zone */}
                  <div
                    className={`
                      relative rounded-lg border-2 border-dashed p-6 text-center transition-colors cursor-pointer
                      ${isDragging 
                        ? 'border-primary bg-primary/5' 
                        : 'border-muted-foreground/25 hover:border-muted-foreground/50'
                      }
                    `}
                    onDrop={handleDrop}
                    onDragOver={handleDragOver}
                    onDragLeave={handleDragLeave}
                    onClick={() => fileInputRef.current?.click()}
                  >
                    <input
                      ref={fileInputRef}
                      type="file"
                      multiple
                      className="hidden"
                      onChange={(e) => e.target.files && handleFiles(e.target.files)}
                    />
                    
                    <Upload className="mx-auto h-10 w-10 text-muted-foreground" />
                    <p className="mt-2 text-sm text-muted-foreground">
                      Drag and drop files here, or{' '}
                      <span className="font-medium text-primary">browse</span>
                    </p>
                    <p className="mt-1 text-xs text-muted-foreground">
                      All files will be encrypted together with your message
                    </p>
                  </div>

                  {/* File List */}
                  {filesToEncrypt.length > 0 && (
                    <div className="space-y-2 mt-4">
                      <p className="text-sm font-medium">Files to encrypt:</p>
                      {filesToEncrypt.map((fileItem) => (
                        <div key={fileItem.id} className="flex items-center justify-between rounded-lg border p-2">
                          <div className="flex-1 min-w-0">
                            <p className="text-sm truncate">{fileItem.file.name}</p>
                            <p className="text-xs text-muted-foreground">
                              {formatBytes(fileItem.file.size)}
                            </p>
                          </div>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => removeFile(fileItem.id)}
                          >
                            <X className="h-4 w-4" />
                          </Button>
                        </div>
                      ))}
                      <p className="text-xs text-muted-foreground">
                        Total size: {formatBytes(getTotalFileSize())} / {uploadLimitMB}MB
                      </p>
                    </div>
                  )}
                </div>

                {/* Progress Bar */}
                {isEncrypting && (
                  <div className="space-y-2">
                    <Progress value={uploadProgress} />
                    <p className="text-sm text-center text-muted-foreground">
                      {uploadProgress < 90 ? 'Encrypting...' : 'Uploading...'} {uploadProgress}%
                    </p>
                  </div>
                )}

                {/* Encrypt Button */}
                <Button
                  onClick={handleEncryptAll}
                  disabled={isEncrypting || !password || (validatePassword(password) !== null) || (!message && filesToEncrypt.length === 0)}
                  className="w-full"
                >
                  {isEncrypting ? "Encrypting..." : "Encrypt All"}
                </Button>
              </CardContent>
            </Card>

            {/* Info Alert */}
            <Alert>
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>
                Your message and all files will be encrypted together into a single package.
                Recipients will need the password to decrypt everything.
              </AlertDescription>
            </Alert>
          </div>
        ) : (
          <Card>
            <CardHeader>
              <CardTitle className="text-green-600 dark:text-green-400">
                ✓ Encryption Successful
              </CardTitle>
              <CardDescription>
                Your data has been encrypted and stored. Share this link with recipients.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label>Shareable Link</Label>
                <div className="rounded-lg border bg-muted p-4 text-center">
                  <p className="font-mono text-sm break-all">{shareableLink}</p>
                </div>
                <Button
                  onClick={copyToClipboard}
                  variant="outline"
                  className="w-full"
                >
                  <Copy className="mr-2 size-4" />
                  Copy Link
                </Button>
              </div>

              <div className="rounded-lg bg-muted p-4">
                <p className="text-sm font-semibold">What was encrypted:</p>
                <ul className="mt-2 space-y-1 text-sm text-muted-foreground">
                  {message && <li>• Text message (formatted)</li>}
                  {filesToEncrypt.length > 0 && <li>• {filesToEncrypt.length} file{filesToEncrypt.length > 1 ? 's' : ''}</li>}
                  <li>• Encrypted with AES-256-GCM</li>
                  <li>• Stored on server for 24 hours</li>
                  {user && <li>• Linked to your account</li>}
                </ul>
              </div>

              <Button onClick={reset} variant="outline" className="w-full">
                Encrypt More Data
              </Button>
            </CardContent>
          </Card>
        )}
      </div>
    </section>
  )
}
