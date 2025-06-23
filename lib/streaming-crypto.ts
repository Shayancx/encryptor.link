/**
 * Streaming crypto implementation for chunked file encryption
 * Uses AES-GCM with per-chunk encryption for memory efficiency
 */

const CHUNK_SIZE = 1024 * 1024 // 1MB chunks
const PBKDF2_ITERATIONS = 250000
const MAX_RETRIES = 3
const RETRY_DELAY = 1000 // 1 second

export interface StreamingUploadSession {
  sessionId: string
  fileId: string
  totalChunks: number
  uploadedChunks: number
}

/**
 * Convert ArrayBuffer to base64 string safely
 */
function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  const chunks: string[] = []
  const chunkSize = 0x8000 // 32KB chunks to avoid call stack issues
  
  for (let i = 0; i < bytes.length; i += chunkSize) {
    const chunk = bytes.subarray(i, i + chunkSize)
    chunks.push(String.fromCharCode(...chunk))
  }
  
  return btoa(chunks.join(''))
}

/**
 * Convert base64 string to ArrayBuffer
 */
function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binary = atob(base64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

/**
 * Derive encryption key from password
 */
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

/**
 * Sleep function for retries
 */
function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

/**
 * Initialize a streaming upload session
 */
export async function initializeStreamingUpload(
  filename: string,
  fileSize: number,
  mimeType: string,
  password: string,
  authToken?: string
): Promise<StreamingUploadSession> {
  const totalChunks = Math.ceil(fileSize / CHUNK_SIZE)
  
  const headers: Record<string, string> = {
    'Content-Type': 'application/json'
  }
  
  if (authToken) {
    headers['Authorization'] = `Bearer ${authToken}`
  }

  const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/streaming/initialize`, {
    method: 'POST',
    headers,
    body: JSON.stringify({
      filename,
      fileSize,
      mimeType,
      password,
      totalChunks,
      chunkSize: CHUNK_SIZE
    })
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({ error: 'Failed to initialize upload' }))
    throw new Error(error.error || `HTTP ${response.status}`)
  }

  const data = await response.json()
  
  return {
    sessionId: data.session_id,
    fileId: data.file_id,
    totalChunks,
    uploadedChunks: 0
  }
}

/**
 * Encrypt a chunk of data
 */
async function encryptChunk(
  chunk: ArrayBuffer,
  key: CryptoKey
): Promise<{ encryptedData: ArrayBuffer; iv: Uint8Array }> {
  const iv = crypto.getRandomValues(new Uint8Array(12))
  
  const encryptedData = await crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv: iv
    },
    key,
    chunk
  )
  
  return { encryptedData, iv }
}

/**
 * Upload a single chunk with retry logic
 */
async function uploadChunkWithRetry(
  chunk: ArrayBuffer,
  chunkIndex: number,
  session: StreamingUploadSession,
  password: string,
  salt: Uint8Array,
  maxRetries: number = MAX_RETRIES,
  onProgress?: (uploaded: number, total: number) => void,
  signal?: AbortSignal
): Promise<void> {
  const key = await deriveKey(password, salt)
  
  let lastError: Error | null = null
  
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    if (signal?.aborted) {
      throw new Error('Upload cancelled')
    }
    
    try {
      // Encrypt the chunk
      const { encryptedData, iv } = await encryptChunk(chunk, key)
      
      // Create form data for multipart upload
      const formData = new FormData()
      formData.append('session_id', session.sessionId)
      formData.append('chunk_index', chunkIndex.toString())
      formData.append('iv', arrayBufferToBase64(iv.buffer))
      
      // Create blob from encrypted data
      const blob = new Blob([encryptedData], { type: 'application/octet-stream' })
      formData.append('chunk_data', blob, `chunk_${chunkIndex}`)
      
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 30000) // 30 second timeout
      
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
      
      if (!response.ok) {
        let errorMessage = `HTTP ${response.status}`
        try {
          const errorData = await response.json()
          errorMessage = errorData.error || errorMessage
        } catch {
          // Ignore JSON parse errors
        }
        throw new Error(`Failed to upload chunk ${chunkIndex}: ${errorMessage}`)
      }
      
      const result = await response.json()
      
      // Validate response
      if (!result.chunks_received || !result.total_chunks) {
        throw new Error(`Invalid response for chunk ${chunkIndex}`)
      }
      
      session.uploadedChunks = result.chunks_received
      
      if (onProgress) {
        onProgress(session.uploadedChunks, session.totalChunks)
      }
      
      // Success! Exit retry loop
      return
      
    } catch (error: any) {
      lastError = error
      console.warn(`Chunk ${chunkIndex} upload attempt ${attempt + 1} failed:`, error.message)
      
      if (attempt < maxRetries - 1) {
        // Exponential backoff
        const delay = RETRY_DELAY * Math.pow(2, attempt)
        console.log(`Retrying in ${delay}ms...`)
        await sleep(delay)
      }
    }
  }
  
  // All retries failed
  throw lastError || new Error(`Failed to upload chunk ${chunkIndex} after ${maxRetries} attempts`)
}

/**
 * Finalize the streaming upload
 */
export async function finalizeStreamingUpload(
  session: StreamingUploadSession,
  salt: string
): Promise<{ fileId: string; shareableLink: string }> {
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
    throw new Error(error.error || `HTTP ${response.status}`)
  }

  const data = await response.json()
  return {
    fileId: data.file_id,
    shareableLink: `${window.location.origin}/view/${data.file_id}`
  }
}

/**
 * Optimized file chunk reading
 */
export async function* readFileInChunks(
  file: File,
  chunkSize: number = CHUNK_SIZE
): AsyncGenerator<{ chunk: ArrayBuffer; index: number }, void, undefined> {
  let offset = 0
  let index = 0
  
  while (offset < file.size) {
    const end = Math.min(offset + chunkSize, file.size)
    const slice = file.slice(offset, end)
    const arrayBuffer = await slice.arrayBuffer()
    
    yield { chunk: arrayBuffer, index }
    offset = end
    index++
  }
}

/**
 * Stream encrypt and upload a file
 */
export async function streamEncryptAndUpload(
  file: File,
  password: string,
  authToken?: string,
  onProgress?: (progress: number) => void,
  signal?: AbortSignal
): Promise<{ fileId: string; shareableLink: string }> {
  console.log(`[Upload] Starting upload for ${file.name}`, {
    size: file.size,
    type: file.type,
    chunks: Math.ceil(file.size / CHUNK_SIZE)
  })
  
  // Generate salt for this upload
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
    
    console.log(`[Upload] Session initialized:`, session)
  } catch (error: any) {
    console.error('[Upload] Failed to initialize session:', error)
    throw new Error(`Failed to start upload: ${error.message}`)
  }

  const uploadPromises: Promise<void>[] = []
  const MAX_CONCURRENT_UPLOADS = 3

  try {
    // Process file in chunks
    for await (const { chunk, index } of readFileInChunks(file)) {
      if (signal?.aborted) {
        throw new Error('Upload cancelled')
      }
      
      // Wait if we have too many concurrent uploads
      while (uploadPromises.length >= MAX_CONCURRENT_UPLOADS) {
        // Wait for at least one to complete
        await Promise.race(uploadPromises)
        
        // Remove completed promises
        for (let i = uploadPromises.length - 1; i >= 0; i--) {
          if (await Promise.race([uploadPromises[i], Promise.resolve('done')]) === 'done') {
            uploadPromises.splice(i, 1)
          }
        }
      }

      console.log(`[Upload] Queueing chunk ${index + 1}/${session.totalChunks}`)
      
      // Upload chunk with retry
      const uploadPromise = uploadChunkWithRetry(
        chunk,
        index,
        session,
        password,
        salt,
        MAX_RETRIES,
        (uploaded, total) => {
          if (onProgress) {
            const progress = (uploaded / total) * 100
            console.log(`[Upload] Progress: ${progress.toFixed(1)}%`)
            onProgress(progress)
          }
        },
        signal
      ).catch(error => {
        console.error(`[Upload] Chunk ${index} failed permanently:`, error)
        throw error
      })

      uploadPromises.push(uploadPromise)
    }

    // Wait for all uploads to complete
    console.log('[Upload] Waiting for all chunks to complete...')
    await Promise.all(uploadPromises)
    
    console.log('[Upload] All chunks uploaded, finalizing...')

    // Finalize upload
    const result = await finalizeStreamingUpload(session, saltBase64)
    
    console.log('[Upload] Upload completed successfully:', result)
    return result
    
  } catch (error: any) {
    console.error('[Upload] Upload failed:', error)
    throw new Error(`Upload failed: ${error.message}`)
  }
}

/**
 * Download and decrypt file in chunks
 */
export async function streamDownloadAndDecrypt(
  fileId: string,
  password: string,
  onProgress?: (progress: number) => void
): Promise<{ blob: Blob; filename: string; mimetype: string }> {
  // Get file info
  const infoResponse = await fetch(
    `${process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api'}/streaming/info/${fileId}`
  )
  
  if (!infoResponse.ok) {
    throw new Error('Failed to get file info')
  }

  const fileInfo = await infoResponse.json()
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

  // Combine chunks into blob
  const blob = new Blob(decryptedChunks, { type: fileInfo.mime_type })
  
  return {
    blob,
    filename: fileInfo.filename,
    mimetype: fileInfo.mime_type
  }
}
