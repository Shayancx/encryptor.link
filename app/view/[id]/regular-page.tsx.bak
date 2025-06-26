"use client"
import { parseCombinedPayload } from "@/lib/decrypt-combined"

import { useState, useEffect } from "react"
import { Download, FileText, Lock, Unlock, FileAudio, AlertCircle } from "lucide-react"

import { decrypt } from "@/lib/crypto"
import { streamDownloadAndDecrypt } from "@/lib/streaming-crypto"
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

export default function ViewPage({ params }: { params: { id: string } }) {
  const [password, setPassword] = useState("")
  const [decryptedMessage, setDecryptedMessage] = useState<string | null>(null)
  const [decryptedFiles, setDecryptedFiles] = useState<DecryptedFile[]>([])
  const [isDecrypting, setIsDecrypting] = useState(false)
  const [downloadProgress, setDownloadProgress] = useState(0)
  const [error, setError] = useState<string | null>(null)
  const [isHtmlContent, setIsHtmlContent] = useState(false)
  const [isChunkedFile, setIsChunkedFile] = useState<boolean | null>(null)
  
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

  // Check if file is chunked
  useEffect(() => {
    checkFileType()
  }, [params.id])

  const checkFileType = async () => {
    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/streaming/info/${params.id}`
      )
      
      if (response.ok) {
        setIsChunkedFile(true)
      } else {
        setIsChunkedFile(false)
      }
    } catch {
      setIsChunkedFile(false)
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
      if (isChunkedFile) {
        // Handle chunked file download
        const result = await streamDownloadAndDecrypt(
          params.id,
          password,
          (progress) => setDownloadProgress(progress)
        )

        const blobUrl = URL.createObjectURL(result.blob)
        
        setDecryptedFiles([{
          filename: result.filename,
          mimetype: result.mimetype,
          size: result.blob.size,
          data: await result.blob.arrayBuffer(),
          blobUrl: result.mimetype.startsWith('audio/') ? blobUrl : undefined
        }])

        toast({
          title: "Decryption successful",
          description: "Your file has been decrypted"
        })
      } else {
        // Handle regular (non-chunked) download
        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/download/${params.id}`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({ password })
          }
        )
        
        if (!response.ok) {
          const error = await response.json()
          throw new Error(error.error || 'Failed to retrieve data')
        }

        const result = await response.json()
        
        // Decode the combined encrypted data
        const combinedData = parseCombinedPayload(result.encrypted_data)
        
        // Decrypt message if present
        if (combinedData.message) {
          const messagePayload = {
            version: 1,
            type: 'text' as const,
            iv: combinedData.message.iv,
            salt: combinedData.message.salt,
            ciphertext: combinedData.message.ciphertext
          }
          
          const decryptedMsg = await decrypt(messagePayload, password)
          setDecryptedMessage(decryptedMsg.data as string)
          setIsHtmlContent(combinedData.message.isHtml === true)
        }
        
        // Decrypt files if present
        if (combinedData.files && combinedData.files.length > 0) {
          const decryptedFilesList: DecryptedFile[] = []
          
          for (const encFile of combinedData.files) {
            const filePayload = {
              version: 1,
              type: 'file' as const,
              iv: encFile.iv,
              salt: encFile.salt,
              ciphertext: encFile.ciphertext,
              filename: encFile.filename
            }
            
            const decryptedFile = await decrypt(filePayload, password)
            let fileData = decryptedFile.data as ArrayBuffer
            
            // Ensure we have an ArrayBuffer
            if (fileData instanceof Uint8Array) {
              fileData = fileData.buffer.slice(fileData.byteOffset, fileData.byteOffset + fileData.byteLength)
            }
            
            // Create blob URL for audio files
            let blobUrl: string | undefined
            if (encFile.mimetype.startsWith('audio/')) {
              const uint8Array = new Uint8Array(fileData)
              const blob = new Blob([uint8Array], { type: encFile.mimetype })
              blobUrl = URL.createObjectURL(blob)
            }
            
            decryptedFilesList.push({
              filename: encFile.filename,
              mimetype: encFile.mimetype,
              size: fileData.byteLength,
              data: fileData,
              blobUrl
            })
          }
          
          setDecryptedFiles(decryptedFilesList)
        }

        toast({
          title: "Decryption successful",
          description: "Your data has been decrypted"
        })
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
    const uint8Array = new Uint8Array(file.data)
    const blob = new Blob([uint8Array], { type: file.mimetype })
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

  const handleSongsLoaded = (loadedSongs: Song[]) => {
    setSongs(loadedSongs)
  }

  const handlePlaySong = (song: Song, index: number) => {
    setCurrentSong(song)
    setCurrentSongIndex(index)
    setIsPlayerOpen(true)
    setIsPlaying(true)
    
    if (shuffle) {
      setPlayHistory([...playHistory, index])
    }
  }

  const handlePrevious = () => {
    if (songs.length <= 1) return

    let prevIndex: number
    
    if (shuffle && playHistory.length > 1) {
      // Go back in shuffle history
      const newHistory = [...playHistory]
      newHistory.pop()
      prevIndex = newHistory[newHistory.length - 1]
      setPlayHistory(newHistory)
    } else {
      prevIndex = (currentSongIndex - 1 + songs.length) % songs.length
    }
    
    setCurrentSongIndex(prevIndex)
    setCurrentSong(songs[prevIndex])
  }

  const handleNext = () => {
    if (songs.length <= 1) return

    if (repeat === 'one') {
      // Restart current song
      setIsPlaying(false)
      setTimeout(() => setIsPlaying(true), 100)
      return
    }

    let nextIndex: number
    
    if (shuffle) {
      const availableIndices = Array.from({ length: songs.length }, (_, i) => i)
        .filter(i => i !== currentSongIndex)
      nextIndex = availableIndices[Math.floor(Math.random() * availableIndices.length)]
      setPlayHistory([...playHistory, nextIndex])
    } else {
      nextIndex = (currentSongIndex + 1) % songs.length
      if (nextIndex === 0 && repeat !== 'all') {
        setIsPlaying(false)
        return
      }
    }
    
    setCurrentSongIndex(nextIndex)
    setCurrentSong(songs[nextIndex])
  }

  const toggleRepeat = () => {
    const modes: Array<'none' | 'all' | 'one'> = ['none', 'all', 'one']
    const currentIndex = modes.indexOf(repeat)
    setRepeat(modes[(currentIndex + 1) % modes.length])
  }

  const copyToClipboard = async () => {
    if (!decryptedMessage) return

    try {
      const textToCopy = isHtmlContent 
        ? decryptedMessage.replace(/<[^>]*>/g, '') 
        : decryptedMessage
      
      await navigator.clipboard.writeText(textToCopy)
      toast({
        title: "Copied to clipboard",
        description: "The message has been copied (plain text)"
      })
    } catch (error) {
      toast({
        title: "Copy failed",
        description: "Failed to copy to clipboard",
        variant: "destructive"
      })
    }
  }

  // Separate audio files from other files
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
                  This data is encrypted. Enter your password to decrypt it.
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
                      {isChunkedFile ? 'Downloading and decrypting chunks...' : 'Decrypting...'}
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

                {isChunkedFile && (
                  <Alert>
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription>
                      This is a large file that was uploaded in chunks. 
                      It will be downloaded and decrypted progressively.
                    </AlertDescription>
                  </Alert>
                )}

                <div className="rounded-lg bg-muted p-4">
                  <p className="text-sm font-semibold">Security Process:</p>
                  <ul className="mt-2 space-y-1 text-sm text-muted-foreground">
                    <li>• Password sent securely via POST</li>
                    <li>• Server verifies against salted hash</li>
                    {isChunkedFile && <li>• File downloaded in encrypted chunks</li>}
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
                    Your data has been decrypted successfully.
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
                    {isHtmlContent ? (
                      <TiptapEditor
                        content={decryptedMessage}
                        readOnly={true}
                        className="min-h-[150px]"
                      />
                    ) : (
                      <div className="rounded-md border bg-background p-4">
                        <pre className="whitespace-pre-wrap font-mono text-sm">{decryptedMessage}</pre>
                      </div>
                    )}
                    <Button
                      onClick={copyToClipboard}
                      variant="outline"
                      className="w-full"
                    >
                      Copy Message (Plain Text)
                    </Button>
                  </CardContent>
                </Card>
              )}

              {/* Audio Files - Song List */}
              {audioFiles.length > 0 && (
                <SongList 
                  files={audioFiles}
                  onPlaySong={handlePlaySong}
                  currentSongId={currentSong?.id}
                  isPlaying={isPlaying}
                  onSongsLoaded={handleSongsLoaded}
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

      {/* Player Bar */}
      <PlayerBar
        currentSong={currentSong}
        isOpen={isPlayerOpen}
        onClose={() => {
          setIsPlayerOpen(false)
          setIsPlaying(false)
        }}
        onPrevious={handlePrevious}
        onNext={handleNext}
        onDownload={() => {
          const currentFile = audioFiles[currentSongIndex]
          if (currentFile) handleDownloadFile(currentFile)
        }}
        isPlaying={isPlaying}
        onPlayPause={setIsPlaying}
        shuffle={shuffle}
        onShuffleToggle={() => {
          setShuffle(!shuffle)
          setPlayHistory([currentSongIndex])
        }}
        repeat={repeat}
        onRepeatToggle={toggleRepeat}
      />

      {/* Add padding when player is open */}
      {isPlayerOpen && <div className="h-20" />}
    </>
  )
}
