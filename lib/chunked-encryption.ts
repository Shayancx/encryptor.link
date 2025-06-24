/**
 * Chunked encryption for large files
 * Encrypts files in chunks to avoid memory issues
 */

import { streamEncryptAndUpload } from './streaming-crypto'

export interface ChunkedFile {
  filename: string
  mimetype: string
  size: number
  file: File
}

export async function encryptLargeFiles(
  files: ChunkedFile[],
  message: string | null,
  password: string,
  authToken?: string,
  onProgress?: (progress: number) => void
): Promise<{ fileId: string; shareableLink: string }> {
  // For now, we'll use the streaming upload for very large files
  // In the future, this can be enhanced to handle multiple large files
  
  if (files.length === 1 && files[0].size > 50 * 1024 * 1024) {
    // Single large file - use streaming
    return streamEncryptAndUpload(
      files[0].file,
      password,
      authToken,
      onProgress
    )
  }
  
  // For multiple files or smaller files, use regular encryption
  throw new Error('Use regular encryption for multiple or smaller files')
}
