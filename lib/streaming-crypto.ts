/**
 * Enhanced streaming crypto implementation with bulletproof reliability
 */

import { StreamingLogger } from './streaming-logger'

const CHUNK_SIZE = 1024 * 1024 // 1MB chunks
const PBKDF2_ITERATIONS = 250000
const MAX_RETRIES = 3
const RETRY_DELAY = 1000
const UPLOAD_TIMEOUT = 30000 // 30 seconds per chunk
const MAX_CONCURRENT_UPLOADS = 2 // Reduced for stability

export interface StreamingUploadSession {
  sessionId: string
  fileId: string
  totalChunks: number
  uploadedChunks: number
  chunkStatuses: Map<number, 'pending' | 'uploading' | 'completed' | 'failed'>
}

export interface ChunkUploadResult {
  success: boolean
  chunkIndex: number
  error?: string
}

// Utility functions
function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  const chunks: string[] = []
  const chunkSize = 0x8000
  
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize)
    chunks.push(String.fromCharCode(...chunk))
  }
  
  return btoa(chunks.join(''))
}

function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binary = atob(base64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

async function deriveKey(password: string, salt: Uint8Array): Promise<CryptoKey> {
  const encoder = new TextEncoder()
  const passwordKey = await crypto.subtle.importKey(
    'raw',
    encoder.encode(password),
    'PBKDF2',
    false,
    ['deriveBits', 'deriveKey']
  )

  return crypto.subtle.deriveKey(
    {
      name: 'PBKDF2',
      salt: salt,
      iterations: PBKDF2_ITERATIONS,
      hash: 'SHA-256'
    },
    passwordKey,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  )
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

// Initialize streaming upload with validation
export async function initializeStreamingUpload(
  filename: string,
  fileSize: number,
  mimeType: string,
  password: string,
  authToken?: string
): Promise<StreamingUploadSession> {
  StreamingLogger.log('Init', `Starting upload for ${filename}`, { fileSize, mimeType })
  
  const totalChunks = Math.ceil(fileSize / CHUNK_SIZE)
  
  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  
  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`
  }

  const requestBody = {
    filename,
    fileSize,
    mimeType,
    password,
    totalChunks,
    chunkSize: CHUNK_SIZE
  }

  StreamingLogger.log('Init', 'Sending initialization request', requestBody)

  const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/streaming/initialize`, {
    method: 'POST',
    headers,
    body: JSON.stringify(requestBody)
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Failed to initialize upload' }))
    StreamingLogger.error('Init', 'Initialization failed', error)
    throw new Error(error.error || `HTTP ${response.status}`)
  }

  const data = await response.json()
  StreamingLogger.log('Init', 'Session initialized', data)
  
  return {
    sessionId: data.session_id,
    fileId: data.file_id,
    totalChunks,
    uploadedChunks: 0,
    chunkStatuses: new Map()
  }
}

// Encrypt chunk with error handling
async function encryptChunk(
  chunk: ArrayBuffer,
  key: CryptoKey,
  chunkIndex: number
): Promise<{ encryptedData: ArrayBuffer; iv: Uint8Array }> {
  StreamingLogger.log('Encrypt', `Encrypting chunk ${chunkIndex}`, { size: chunk.byteLength })
  
  try {
    const iv = crypto.getRandomValues(new Uint8Array(12))
    
    const encryptedData = await crypto.subtle.encrypt(
      {
        name: 'AES-GCM',
        iv: iv
      },
      key,
      chunk
    )
    
    StreamingLogger.log('Encrypt', `Chunk ${chunkIndex} encrypted`, { 
      originalSize: chunk.byteLength,
      encryptedSize: encryptedData.byteLength 
    })
    
    return { encryptedData, iv }
  } catch (error) {
    StreamingLogger.error('Encrypt', `Failed to encrypt chunk ${chunkIndex}`, error)
    throw error
  }
}

// Upload single chunk with comprehensive error handling
async function uploadChunkWithRetry(
  chunk: ArrayBuffer,
  chunkIndex: number,
  session: StreamingUploadSession,
  password: string,
  salt: Uint8Array,
  maxRetries: number = MAX_RETRIES,
  signal?: AbortSignal
): Promise<ChunkUploadResult> {
  StreamingLogger.log('Upload', `Starting upload for chunk ${chunkIndex}`, { 
    size: chunk.byteLength,
    sessionId: session.sessionId 
  })
  
  const key = await deriveKey(password, salt)
  
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    if (signal?.aborted) {
      StreamingLogger.log('Upload', `Chunk ${chunkIndex} aborted`)
      return { success: false, chunkIndex, error: 'Upload cancelled' }
    }
    
    try {
      // Update status
      session.chunkStatuses.set(chunkIndex, 'uploading')
      
      // Encrypt the chunk
      const { encryptedData, iv } = await encryptChunk(chunk, key, chunkIndex)
      
      // Create form data
      const formData = new FormData()
      formData.append('session_id', session.sessionId)
      formData.append('chunk_index', chunkIndex.toString())
      formData.append('iv', arrayBufferToBase64(iv.buffer))
      
      // Create blob with proper type
      const blob = new Blob([encryptedData], { type: 'application/octet-stream' })
      formData.append('chunk_data', blob, `chunk_${chunkIndex}.enc`)
      
      // Log form data details
      StreamingLogger.log('Upload', `Uploading chunk ${chunkIndex} attempt ${attempt + 1}`, {
        encryptedSize: encryptedData.byteLength,
        ivLength: iv.length
      })
      
      // Upload with timeout
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), UPLOAD_TIMEOUT)
      
      const uploadSignal = signal ? 
        AbortSignal.any([signal, controller.signal]) : 
        controller.signal
      
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/streaming/chunk`,
        {
          method: 'POST',
          body: formData,
          signal: uploadSignal
        }
      )
      
      clearTimeout(timeoutId)
      
      const responseText = await response.text()
      StreamingLogger.log('Upload', `Chunk ${chunkIndex} response`, { 
        status: response.status,
        response: responseText 
      })
      
      if (!response.ok) {
        let errorMessage = `HTTP ${response.status}`
        try {
          const errorData = JSON.parse(responseText)
          errorMessage = errorData.error || errorMessage
        } catch {
          errorMessage = responseText || errorMessage
        }
        throw new Error(errorMessage)
      }
      
      const result = JSON.parse(responseText)
      
      // Validate response
      if (!result.chunks_received || !result.total_chunks) {
        throw new Error(`Invalid response for chunk ${chunkIndex}: ${responseText}`)
      }
      
      // Update session
      session.uploadedChunks = result.chunks_received
      session.chunkStatuses.set(chunkIndex, 'completed')
      
      StreamingLogger.log('Upload', `Chunk ${chunkIndex} uploaded successfully`, {
        chunksReceived: result.chunks_received,
        totalChunks: result.total_chunks
      })
      
      return { success: true, chunkIndex }
      
    } catch (error: any) {
      StreamingLogger.error('Upload', `Chunk ${chunkIndex} attempt ${attempt + 1} failed`, error)
      
      if (attempt < maxRetries - 1) {
        const delay = RETRY_DELAY * Math.pow(2, attempt)
        StreamingLogger.log('Upload', `Retrying chunk ${chunkIndex} in ${delay}ms...`)
        await sleep(delay)
      } else {
        session.chunkStatuses.set(chunkIndex, 'failed')
        return { success: false, chunkIndex, error: error.message }
      }
    }
  }
  
  return { success: false, chunkIndex, error: 'Max retries exceeded' }
}

// Verify all chunks uploaded
async function verifyChunks(session: StreamingUploadSession): Promise<number[]> {
  const missingChunks: number[] = []
  
  for (let i = 0; i < session.totalChunks; i++) {
    if (session.chunkStatuses.get(i) !== 'completed') {
      missingChunks.push(i)
    }
  }
  
  StreamingLogger.log('Verify', 'Chunk verification', {
    total: session.totalChunks,
    completed: session.totalChunks - missingChunks.length,
    missing: missingChunks
  })
  
  return missingChunks
}

// Finalize upload with verification
export async function finalizeStreamingUpload(
  session: StreamingUploadSession,
  salt: string
): Promise<{ fileId: string; shareableLink: string }> {
  StreamingLogger.log('Finalize', 'Starting finalization', { sessionId: session.sessionId })
  
  // Verify all chunks uploaded
  const missingChunks = await verifyChunks(session)
  if (missingChunks.length > 0) {
    throw new Error(`Cannot finalize: missing chunks ${missingChunks.join(', ')}`)
  }
  
  const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/streaming/finalize`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      session_id: session.sessionId,
      salt: salt
    })
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Failed to finalize upload' }))
    StreamingLogger.error('Finalize', 'Finalization failed', error)
    throw new Error(error.error || `HTTP ${response.status}`)
  }

  const data = await response.json()
  StreamingLogger.log('Finalize', 'Upload finalized', data)
  
  return {
    fileId: data.file_id,
    shareableLink: `${window.location.origin}/view/${data.file_id}`
  }
}

// Enhanced file reading with progress
export async function* readFileInChunks(
  file: File,
  chunkSize: number = CHUNK_SIZE
): AsyncGenerator<{ chunk: ArrayBuffer; index: number; progress: number }, void, undefined> {
  let offset = 0
  let index = 0
  
  while (offset < file.size) {
    const end = Math.min(offset + chunkSize, file.size)
    const slice = file.slice(offset, end)
    
    try {
      const arrayBuffer = await slice.arrayBuffer()
      const progress = (end / file.size) * 100
      
      StreamingLogger.log('Read', `Read chunk ${index}`, { 
        start: offset, 
        end, 
        size: arrayBuffer.byteLength,
        progress: progress.toFixed(1) 
      })
      
      yield { chunk: arrayBuffer, index, progress }
      offset = end
      index++
    } catch (error) {
      StreamingLogger.error('Read', `Failed to read chunk ${index}`, error)
      throw error
    }
  }
}

// Main upload function with enhanced reliability
export async function streamEncryptAndUpload(
  file: File,
  password: string,
  authToken?: string,
  onProgress?: (progress: number) => void,
  signal?: AbortSignal
): Promise<{ fileId: string; shareableLink: string }> {
  StreamingLogger.log('Main', 'Starting streaming upload', {
    fileName: file.name,
    fileSize: file.size,
    fileType: file.type
  })
  
  // Generate salt
  const salt = crypto.getRandomValues(new Uint8Array(32))
  const saltBase64 = arrayBufferToBase64(salt.buffer)

  let session: StreamingUploadSession
  
  try {
    // Initialize session
    session = await initializeStreamingUpload(
      file.name,
      file.size,
      file.type || 'application/octet-stream',
      password,
      authToken
    )
    
    // Initialize chunk statuses
    for (let i = 0; i < session.totalChunks; i++) {
      session.chunkStatuses.set(i, 'pending')
    }
    
  } catch (error: any) {
    StreamingLogger.error('Main', 'Failed to initialize session', error)
    throw new Error(`Failed to start upload: ${error.message}`)
  }

  const uploadQueue: Promise<ChunkUploadResult>[] = []
  const failedChunks: number[] = []
  let lastProgress = 0

  try {
    // Process chunks
    for await (const { chunk, index, progress } of readFileInChunks(file)) {
      if (signal?.aborted) {
        throw new Error('Upload cancelled')
      }
      
      // Wait if queue is full
      while (uploadQueue.length >= MAX_CONCURRENT_UPLOADS) {
        const completed = await Promise.race(uploadQueue)
        uploadQueue.splice(uploadQueue.findIndex(p => p === completed), 1)
        
        if (!completed.success) {
          failedChunks.push(completed.chunkIndex)
        }
      }
      
      // Update progress
      if (onProgress && progress - lastProgress > 1) {
        onProgress(progress * 0.9) // Reserve 10% for finalization
        lastProgress = progress
      }
      
      // Upload chunk
      const uploadPromise = uploadChunkWithRetry(
        chunk,
        index,
        session,
        password,
        salt,
        MAX_RETRIES,
        signal
      )
      
      uploadQueue.push(uploadPromise)
    }
    
    // Wait for remaining uploads
    StreamingLogger.log('Main', 'Waiting for remaining uploads', { 
      remaining: uploadQueue.length 
    })
    
    const results = await Promise.all(uploadQueue)
    
    // Check for failures
    results.forEach(result => {
      if (!result.success) {
        failedChunks.push(result.chunkIndex)
      }
    })
    
    if (failedChunks.length > 0) {
      throw new Error(`Failed to upload chunks: ${failedChunks.join(', ')}`)
    }
    
    // Final verification
    const missingChunks = await verifyChunks(session)
    if (missingChunks.length > 0) {
      // Retry missing chunks once more
      StreamingLogger.log('Main', 'Retrying missing chunks', { missing: missingChunks })
      
      for (const chunkIndex of missingChunks) {
        const { chunk } = await readChunkFromFile(file, chunkIndex, CHUNK_SIZE)
        const result = await uploadChunkWithRetry(
          chunk,
          chunkIndex,
          session,
          password,
          salt,
          1, // Single retry
          signal
        )
        
        if (!result.success) {
          throw new Error(`Failed to upload chunk ${chunkIndex} after retry`)
        }
      }
    }
    
    // Update progress
    if (onProgress) {
      onProgress(95)
    }
    
    // Finalize upload
    StreamingLogger.log('Main', 'Finalizing upload')
    const result = await finalizeStreamingUpload(session, saltBase64)
    
    if (onProgress) {
      onProgress(100)
    }
    
    StreamingLogger.log('Main', 'Upload completed successfully', result)
    return result
    
  } catch (error: any) {
    StreamingLogger.error('Main', 'Upload failed', error)
    throw new Error(`Upload failed: ${error.message}`)
  }
}

// Helper to read specific chunk from file
async function readChunkFromFile(
  file: File,
  chunkIndex: number,
  chunkSize: number
): Promise<{ chunk: ArrayBuffer; index: number }> {
  const start = chunkIndex * chunkSize
  const end = Math.min(start + chunkSize, file.size)
  const slice = file.slice(start, end)
  const chunk = await slice.arrayBuffer()
  return { chunk, index: chunkIndex }
}

// Download and decrypt (unchanged but with logging)
export async function streamDownloadAndDecrypt(
  fileId: string,
  password: string,
  onProgress?: (progress: number) => void
): Promise<{ blob: Blob; filename: string; mimetype: string }> {
  StreamingLogger.log('Download', 'Starting download', { fileId })
  
  // Get file info
  const infoResponse = await fetch(
    `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/streaming/info/${fileId}`
  )
  
  if (!infoResponse.ok) {
    throw new Error('Failed to get file info')
  }

  const fileInfo = await infoResponse.json()
  StreamingLogger.log('Download', 'File info retrieved', fileInfo)
  
  const salt = new Uint8Array(base64ToArrayBuffer(fileInfo.salt))
  const key = await deriveKey(password, salt)

  const decryptedChunks: ArrayBuffer[] = []
  
  // Download and decrypt each chunk
  for (let i = 0; i < fileInfo.total_chunks; i++) {
    const chunkResponse = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/streaming/download/${fileId}/chunk/${i}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ password })
      }
    )

    if (!chunkResponse.ok) {
      throw new Error(`Failed to download chunk ${i}`)
    }

    const chunkData = await chunkResponse.json()
    const encryptedData = base64ToArrayBuffer(chunkData.data)
    const iv = base64ToArrayBuffer(chunkData.iv)

    // Decrypt chunk
    const decryptedChunk = await crypto.subtle.decrypt(
      {
        name: 'AES-GCM',
        iv: new Uint8Array(iv)
      },
      key,
      encryptedData
    )

    decryptedChunks.push(decryptedChunk)
    
    if (onProgress) {
      onProgress(((i + 1) / fileInfo.total_chunks) * 100)
    }
  }

  // Combine chunks
  const blob = new Blob(decryptedChunks, { type: fileInfo.mime_type })
  
  StreamingLogger.log('Download', 'Download completed', {
    filename: fileInfo.filename,
    size: blob.size
  })
  
  return {
    blob,
    filename: fileInfo.filename,
    mimetype: fileInfo.mime_type
  }
}
