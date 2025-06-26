/**
 * Enhanced cryptography for distributed storage
 */

import { StreamingLogger } from './streaming-logger'

export interface EncryptedChunk {
  index: number
  encryptedData: ArrayBuffer
  iv: string
  checksum: string
  metadata: string // Encrypted metadata
}

// Derive chunk-specific key from master key
export async function deriveChunkKey(
  masterKey: CryptoKey,
  chunkIndex: number
): Promise<CryptoKey> {
  const encoder = new TextEncoder()
  const info = encoder.encode(`chunk-${chunkIndex}`)
  
  // Use HKDF to derive chunk key
  const derivedKeyMaterial = await crypto.subtle.deriveBits(
    {
      name: 'HKDF',
      hash: 'SHA-256',
      salt: new Uint8Array(32), // Zero salt for deterministic derivation
      info: info
    },
    masterKey,
    256 // 32 bytes
  )
  
  // Import as AES key
  return crypto.subtle.importKey(
    'raw',
    derivedKeyMaterial,
    { name: 'AES-GCM', length: 256 },
    false,
    ['encrypt', 'decrypt']
  )
}

// Generate checksum for data integrity
export async function generateChecksum(data: ArrayBuffer): Promise<string> {
  const hash = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hash))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')
}

// Encrypt chunk with metadata
export async function encryptChunkWithMetadata(
  chunkData: Uint8Array,
  chunkIndex: number,
  totalChunks: number,
  masterKey: CryptoKey,
  chunkMetadata: any
): Promise<EncryptedChunk> {
  StreamingLogger.log('DistCrypto', `Encrypting chunk ${chunkIndex}`, {
    size: chunkData.length
  })
  
  // Derive chunk-specific key
  const chunkKey = await deriveChunkKey(masterKey, chunkIndex)
  
  // Create metadata
  const metadata = {
    index: chunkIndex,
    total: totalChunks,
    hash: await generateChecksum(chunkData),
    timestamp: Date.now(),
    ...chunkMetadata
  }
  
  // Encrypt metadata separately
  const metadataIv = crypto.getRandomValues(new Uint8Array(12))
  const metadataBytes = new TextEncoder().encode(JSON.stringify(metadata))
  const encryptedMetadata = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: metadataIv },
    chunkKey,
    metadataBytes
  )
  
  // Encrypt chunk data
  const dataIv = crypto.getRandomValues(new Uint8Array(12))
  const encryptedData = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: dataIv },
    chunkKey,
    chunkData
  )
  
  // Combine metadata IV, metadata, data IV into metadata field
  const combinedMetadata = new Uint8Array(
    12 + encryptedMetadata.byteLength + 12
  )
  combinedMetadata.set(metadataIv, 0)
  combinedMetadata.set(new Uint8Array(encryptedMetadata), 12)
  combinedMetadata.set(dataIv, 12 + encryptedMetadata.byteLength)
  
  const checksum = await generateChecksum(encryptedData)
  
  return {
    index: chunkIndex,
    encryptedData,
    iv: arrayBufferToBase64(dataIv),
    checksum,
    metadata: arrayBufferToBase64(combinedMetadata)
  }
}

// Helper function
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

// Decrypt and verify chunks
export async function decryptAndVerifyChunks(
  encryptedChunks: EncryptedChunk[],
  masterKey: CryptoKey
): Promise<Uint8Array[]> {
  const decryptedChunks: Uint8Array[] = new Array(encryptedChunks.length)
  
  await Promise.all(
    encryptedChunks.map(async (chunk) => {
      // Derive chunk key
      const chunkKey = await deriveChunkKey(masterKey, chunk.index)
      
      // Verify checksum
      const currentChecksum = await generateChecksum(chunk.encryptedData)
      if (currentChecksum !== chunk.checksum) {
        throw new Error(`Checksum mismatch for chunk ${chunk.index}`)
      }
      
      // Decrypt chunk
      const decrypted = await crypto.subtle.decrypt(
        { name: 'AES-GCM', iv: base64ToArrayBuffer(chunk.iv) },
        chunkKey,
        chunk.encryptedData
      )
      
      decryptedChunks[chunk.index] = new Uint8Array(decrypted)
    })
  )
  
  return decryptedChunks
}

function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binary = atob(base64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}
