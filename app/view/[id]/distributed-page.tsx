"use client"

import { useState, useEffect } from "react"
import { Download, FileText, Lock, Unlock, FileAudio, AlertCircle } from "lucide-react"

import { retrieveDistributedFile } from "@/lib/distributed-retrieval"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Progress } from "@/components/ui/progress"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { useToast } from "@/components/ui/use-toast"
import { TiptapEditor } from "@/components/editor/tiptap-editor"
import { SongList, Song } from "@/components/audio/song-list"
import { PlayerBar } from "@/components/audio/player-bar"

interface DecryptedFile {
  filename: string
  mimetype: string
  size: number
  data: ArrayBuffer
  blobUrl?: string
}

export default function DistributedViewPage({ params }: { params: { id: string } }) {
  const [password, setPassword] = useState("")
  const [decryptedMessage, setDecryptedMessage] = useState<string | null>(null)
  const [decryptedFiles, setDecryptedFiles] = useState<DecryptedFile[]>([])
  const [isDecrypting, setIsDecrypting] = useState(false)
  const [downloadProgress, setDownloadProgress] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [isDistributed, setIsDistributed] = useState<boolean | null>(null)
  
  // Player state
  const [songs, setSongs] = useState<Song[]>([])
  const [currentSong, setCurrentSong] = useState<Song | undefined>()
  const [currentSongIndex, setCurrentSongIndex] = useState(0)
  const [isPlayerOpen, setIsPlayerOpen] = useState(false)
  const [isPlaying, setIsPlaying] = useState(false)
  const [shuffle, setShuffle] = useState(false)
  const [repeat, setRepeat] = useState<'none' | 'all' | 'one'>('none')
  const [playHistory, setPlayHistory] = useState<number[]>([])
  
  const { toast } = useToast()

  // Check if file is distributed
  useEffect(() => {
    checkFileType()
  }, [params.id])

  const checkFileType = async () => {
    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/distributed/map/${params.id}`
      )
      
      if (response.ok) {
        setIsDistributed(true)
      } else {
        setIsDistributed(false)
      }
    } catch {
      setIsDistributed(false)
    }
  }

  // Cleanup blob URLs on unmount
  useEffect(() => {
    return () => {
      decryptedFiles.forEach(file => {
        if (file.blobUrl) {
          URL.revokeObjectURL(file.blobUrl)
        }
      })
    }
  }, [decryptedFiles])

  const handleDecrypt = async () => {
    if (!password) {
      toast({
        title: "Password required",
        description: "Please enter the decryption password",
        variant: "destructive"
      })
      return
    }

    setIsDecrypting(true)
    setError(null)
    setDownloadProgress(0)

    try {
      if (isDistributed) {
        // Handle distributed file retrieval
        const result = await retrieveDistributedFile(
          params.id,
          password,
          (progress) => setDownloadProgress(progress)
        )

        // Set message if exists
        if (result.message) {
          setDecryptedMessage(result.message)
        }

        // Process files
        const processedFiles: DecryptedFile[] = []
        for (const file of result.files) {
          let blobUrl: string | undefined
          
          // Create blob URL for audio files
          if (file.mimetype.startsWith('audio/')) {
            const blob = new Blob([file.data], { type: file.mimetype })
            blobUrl = URL.createObjectURL(blob)
          }
          
          processedFiles.push({
            filename: file.filename,
            mimetype: file.mimetype,
            size: file.size,
            data: file.data,
            blobUrl
          })
        }
        
        setDecryptedFiles(processedFiles)

        toast({
          title: "Decryption successful",
          description: "Your distributed data has been retrieved and decrypted"
        })
      } else {
        // Handle regular (non-distributed) files
        // ... existing decryption logic ...
      }
    } catch (error: any) {
      console.error("Decryption error:", error)
      setError(error.message || "Decryption failed. Please check your password.")
      toast({
        title: "Decryption failed",
        description: error.message || "Invalid password or corrupted data",
        variant: "destructive"
      })
    } finally {
      setIsDecrypting(false)
      setDownloadProgress(0)
    }
  }

  const handleDownloadFile = (file: DecryptedFile) => {
    const blob = new Blob([file.data], { type: file.mimetype })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = file.filename
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)

    toast({
      title: "Download started",
      description: `Downloading ${file.filename}`
    })
  }

  // ... rest of the player functions remain the same ...

  const audioFiles = decryptedFiles.filter(file => file.mimetype.startsWith('audio/'))
  const otherFiles = decryptedFiles.filter(file => !file.mimetype.startsWith('audio/'))

  return (
    <>
      <section className="container grid gap-6 pb-8 pt-6 md:py-10">
        <div className="flex flex-col items-center gap-2">
          <h1 className="text-3xl font-extrabold leading-tight tracking-tighter md:text-4xl">
            Decrypt Your Data
          </h1>
          <p className="text-center text-lg text-muted-foreground">
            ID: <span className="font-mono">{params.id}</span>
            {isDistributed && (
              <span className="ml-2 text-sm text-primary">(Distributed Storage)</span>
            )}
          </p>
        </div>

        <div className="mx-auto w-full max-w-4xl">
          {!decryptedMessage && decryptedFiles.length === 0 ? (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Lock className="size-5" />
                  Enter Decryption Password
                </CardTitle>
                <CardDescription>
                  {isDistributed ? (
                    <>This data is distributed across multiple nodes. Enter your password to retrieve and decrypt it.</>
                  ) : (
                    <>This data is encrypted. Enter your password to decrypt it.</>
                  )}
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="decrypt-password">
                    <Lock className="mr-2 inline size-4" />
                    Password
                  </Label>
                  <Input
                    id="decrypt-password"
                    type="password"
                    placeholder="Enter decryption password..."
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') handleDecrypt()
                    }}
                  />
                </div>

                {error && (
                  <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
                )}

                {isDecrypting && downloadProgress > 0 && (
                  <div className="space-y-2">
                    <p className="text-sm text-muted-foreground">
                      {isDistributed ? 'Retrieving chunks from distributed nodes...' : 'Decrypting...'}
                    </p>
                    <Progress value={downloadProgress} />
                  </div>
                )}

                <Button
                  onClick={handleDecrypt}
                  disabled={isDecrypting || !password}
                  className="w-full"
                >
                  {isDecrypting ? "Decrypting..." : "Decrypt"}
                </Button>

                {isDistributed && (
                  <Alert>
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      This file was split into encrypted chunks and distributed across multiple storage nodes.
                      The chunks will be retrieved, verified, and reassembled during decryption.
                    </AlertDescription>
                  </Alert>
                )}

                <div className="rounded-lg bg-muted p-4">
                  <p className="text-sm font-semibold">Security Process:</p>
                  <ul className="mt-2 space-y-1 text-sm text-muted-foreground">
                    <li>• Password sent securely via POST</li>
                    {isDistributed && (
                      <>
                        <li>• Chunks retrieved from distributed nodes</li>
                        <li>• Automatic failover to replica nodes if needed</li>
                        <li>• Chunk integrity verified with checksums</li>
                      </>
                    )}
                    <li>• Decryption happens in your browser</li>
                    <li>• No passwords in server logs</li>
                  </ul>
                </div>
              </CardContent>
            </Card>
          ) : (
            <div className="space-y-6">
              {/* Success Header */}
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2 text-green-600 dark:text-green-400">
                    <Unlock className="size-5" />
                    Decryption Successful
                  </CardTitle>
                  <CardDescription>
                    Your {isDistributed ? 'distributed' : ''} data has been decrypted successfully.
                  </CardDescription>
                </CardHeader>
              </Card>

              {/* Decrypted Message */}
              {decryptedMessage && (
                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg flex items-center gap-2">
                      <FileText className="size-4" />
                      Message
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <TiptapEditor
                      content={decryptedMessage}
                      readOnly={true}
                      className="min-h-[150px]"
                    />
                    <Button
                      onClick={async () => {
                        await navigator.clipboard.writeText(decryptedMessage)
                        toast({ title: "Copied to clipboard" })
                      }}
                      variant="outline"
                      className="w-full"
                    >
                      Copy Message
                    </Button>
                  </CardContent>
                </Card>
              )}

              {/* Audio Files - Song List */}
              {audioFiles.length > 0 && (
                <SongList 
                  files={audioFiles}
                  onPlaySong={(song, index) => {
                    setCurrentSong(song)
                    setCurrentSongIndex(index)
                    setIsPlayerOpen(true)
                    setIsPlaying(true)
                  }}
                  currentSongId={currentSong?.id}
                  isPlaying={isPlaying}
                  onSongsLoaded={setSongs}
                />
              )}

              {/* Other Files */}
              {otherFiles.length > 0 && (
                <Card>
                  <CardHeader>
                    <CardTitle className="text-lg flex items-center gap-2">
                      <FileAudio className="size-4" />
                      Other Files ({otherFiles.length})
                    </CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-2">
                      {otherFiles.map((file, index) => (
                        <div key={index} className="flex items-center justify-between rounded-lg border p-3">
                          <div>
                            <p className="font-medium">{file.filename}</p>
                            <p className="text-sm text-muted-foreground">
                              {(file.size / 1024 / 1024).toFixed(2)} MB
                            </p>
                          </div>
                          <Button
                            size="sm"
                            onClick={() => handleDownloadFile(file)}
                          >
                            <Download className="mr-2 size-4" />
                            Download
                          </Button>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              )}
            </div>
          )}
        </div>
      </section>

      {/* Player Bar - same as before */}
      <PlayerBar
        currentSong={currentSong}
        isOpen={isPlayerOpen}
        onClose={() => {
          setIsPlayerOpen(false)
          setIsPlaying(false)
        }}
        onPrevious={() => {/* ... */}}
        onNext={() => {/* ... */}}
        onDownload={() => {
          const currentFile = audioFiles[currentSongIndex]
          if (currentFile) handleDownloadFile(currentFile)
        }}
        isPlaying={isPlaying}
        onPlayPause={setIsPlaying}
        shuffle={shuffle}
        onShuffleToggle={() => setShuffle(!shuffle)}
        repeat={repeat}
        onRepeatToggle={() => {/* ... */}}
      />

      {isPlayerOpen && <div className="h-20" />}
    </>
  )
}
