/**
 * Distributed chunking implementation for decentralized storage
 */

import { StreamingLogger } from './streaming-logger'

export interface DistributedChunk {
  index: number
  data: Uint8Array
  metadata: ChunkMetadata
}

export interface ChunkMetadata {
  originalFileIndex?: number
  originalFileName?: string
  startOffset: number
  endOffset: number
  isMessageChunk: boolean
}

export interface DistributedUploadSession {
  sessionId: string
  fileId: string
  chunks: DistributedChunk[]
  totalSize: number
  chunkCount: number
}

// Secure random number generator
async function generateSecureRandomNumber(min: number, max: number): Promise<number> {
  const range = max - min + 1
  const bytesNeeded = Math.ceil(Math.log2(range) / 8)
  const randomBytes = new Uint8Array(bytesNeeded)
  crypto.getRandomValues(randomBytes)
  
  let randomNumber = 0
  for (let i = 0; i < bytesNeeded; i++) {
    randomNumber = (randomNumber << 8) | randomBytes[i]
  }
  
  return min + (randomNumber % range)
}

// Process file into chunks without loading entire file into memory
async function processFileIntoChunks(
  file: File,
  fileIndex: number,
  chunks: DistributedChunk[],
  currentChunk: Uint8Array,
  currentOffset: number,
  chunkSize: number,
  globalOffset: number
): Promise<{ currentOffset: number; globalOffset: number }> {
  const reader = file.stream().getReader()
  let fileOffset = 0
  
  try {
    while (true) {
      const { done, value } = await reader.read()
      if (done) break
      
      let sourceOffset = 0
      while (sourceOffset < value.length) {
        const spaceInChunk = chunkSize - currentOffset
        const bytesToCopy = Math.min(spaceInChunk, value.length - sourceOffset)
        
        // Copy data to current chunk
        currentChunk.set(
          value.subarray(sourceOffset, sourceOffset + bytesToCopy),
          currentOffset
        )
        
        currentOffset += bytesToCopy
        sourceOffset += bytesToCopy
        fileOffset += bytesToCopy
        
        // If chunk is full, save it
        if (currentOffset === chunkSize) {
          chunks.push({
            index: chunks.length,
            data: new Uint8Array(currentChunk),
            metadata: {
              originalFileIndex: fileIndex,
              originalFileName: file.name,
              startOffset: globalOffset - currentOffset,
              endOffset: globalOffset,
              isMessageChunk: false
            }
          })
          
          currentChunk = new Uint8Array(chunkSize)
          currentOffset = 0
        }
      }
    }
  } finally {
    reader.releaseLock()
  }
  
  return { currentOffset, globalOffset: globalOffset + fileOffset }
}

// Main distributed chunking function
export async function createDistributedChunks(
  files: File[],
  message: string | null,
  password: string
): Promise<DistributedUploadSession> {
  StreamingLogger.log('DistChunk', 'Starting distributed chunking', {
    fileCount: files.length,
    hasMessage: !!message
  })
  
  // Calculate total size
  const messageBlob = message ? new Blob([message]) : null
  const totalSize = files.reduce((sum, f) => sum + f.size, 0) + 
                   (messageBlob ? messageBlob.size : 0)
  
  // Generate random chunk count (4-9)
  const chunkCount = await generateSecureRandomNumber(4, 9)
  const chunkSize = Math.ceil(totalSize / chunkCount)
  
  StreamingLogger.log('DistChunk', 'Chunk distribution calculated', {
    totalSize,
    chunkCount,
    chunkSize
  })
  
  // Create chunks with metadata
  const chunks: DistributedChunk[] = []
  let currentChunk = new Uint8Array(chunkSize)
  let currentOffset = 0
  let globalOffset = 0
  
  // Process message first if exists
  if (message && messageBlob) {
    const messageData = new Uint8Array(await messageBlob.arrayBuffer())
    let messageOffset = 0
    
    while (messageOffset < messageData.length) {
      const spaceInChunk = chunkSize - currentOffset
      const bytesToCopy = Math.min(spaceInChunk, messageData.length - messageOffset)
      
      currentChunk.set(
        messageData.subarray(messageOffset, messageOffset + bytesToCopy),
        currentOffset
      )
      
      currentOffset += bytesToCopy
      messageOffset += bytesToCopy
      
      if (currentOffset === chunkSize) {
        chunks.push({
          index: chunks.length,
          data: new Uint8Array(currentChunk),
          metadata: {
            startOffset: globalOffset - currentOffset,
            endOffset: globalOffset,
            isMessageChunk: true
          }
        })
        
        currentChunk = new Uint8Array(chunkSize)
        currentOffset = 0
      }
    }
    
    globalOffset += messageData.length
  }
  
  // Process all files
  for (let i = 0; i < files.length; i++) {
    const result = await processFileIntoChunks(
      files[i],
      i,
      chunks,
      currentChunk,
      currentOffset,
      chunkSize,
      globalOffset
    )
    
    currentOffset = result.currentOffset
    globalOffset = result.globalOffset
  }
  
  // Handle remaining data in last chunk
  if (currentOffset > 0) {
    const finalChunk = new Uint8Array(currentOffset)
    finalChunk.set(currentChunk.subarray(0, currentOffset))
    
    chunks.push({
      index: chunks.length,
      data: finalChunk,
      metadata: {
        startOffset: globalOffset - currentOffset,
        endOffset: globalOffset,
        isMessageChunk: false
      }
    })
  }
  
  // Generate session ID
  const sessionId = Array.from(crypto.getRandomValues(new Uint8Array(16)))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')
  
  const fileId = Array.from(crypto.getRandomValues(new Uint8Array(4)))
    .map(b => b.toString(36))
    .join('')
  
  StreamingLogger.log('DistChunk', 'Chunking complete', {
    actualChunks: chunks.length,
    sessionId,
    fileId
  })
  
  return {
    sessionId,
    fileId,
    chunks,
    totalSize,
    chunkCount: chunks.length
  }
}

// Initialize distributed upload
export async function initializeDistributedUpload(
  files: File[],
  message: string | null,
  password: string,
  authToken?: string
): Promise<{ sessionId: string; totalChunks: number; fileId: string }> {
  const session = await createDistributedChunks(files, message, password)
  
  // Initialize with backend
  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  
  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`
  }
  
  const response = await fetch(
    `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/distributed/initialize`,
    {
      method: 'POST',
      headers,
      body: JSON.stringify({
        sessionId: session.sessionId,
        fileId: session.fileId,
        totalChunks: session.chunks.length,
        totalSize: session.totalSize,
        password,
        metadata: {
          fileCount: files.length,
          hasMessage: !!message,
          chunkDistribution: session.chunks.map(c => ({
            index: c.index,
            size: c.data.length,
            metadata: c.metadata
          }))
        }
      })
    }
  )
  
  if (!response.ok) {
    throw new Error('Failed to initialize distributed upload')
  }
  
  return {
    sessionId: session.sessionId,
    totalChunks: session.chunks.length,
    fileId: session.fileId
  }
}
