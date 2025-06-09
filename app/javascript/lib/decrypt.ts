// Web Crypto API wrapper for decryption
export async function decryptMessage(
  ciphertextBase64: string,
  ivBase64: string,
  keyBase64: string | null = null,
  password: string = '',
  passwordSaltBase64: string = ''
): Promise<string> {
  try {
    const key = await getDecryptionKey(keyBase64, password, passwordSaltBase64);
    const ciphertext = Base64.decode(ciphertextBase64);
    const iv = Base64.decode(ivBase64);
    const decrypted = await window.crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, ciphertext);
    const decoder = new TextDecoder();
    return decoder.decode(decrypted);
  } catch (error) {
    console.error('Decryption error:', error);
    throw new Error('Failed to decrypt the message. The key might be incorrect.');
  }
}

export async function decryptFile(
  fileDataBase64: string,
  ivBase64: string,
  keyBase64: string | null = null,
  password: string = '',
  passwordSaltBase64: string = ''
): Promise<ArrayBuffer> {
  try {
    const key = await getDecryptionKey(keyBase64, password, passwordSaltBase64);
    const fileData = Base64.decode(fileDataBase64);
    const iv = Base64.decode(ivBase64);
    const decrypted = await window.crypto.subtle.decrypt({ name: 'AES-GCM', iv }, key, fileData);
    return decrypted;
  } catch (error) {
    console.error('File decryption error:', error);
    throw new Error('Failed to decrypt the file. The key might be incorrect.');
  }
}

export interface DecryptChunk {
  data: string;
  size: number;
  offset: number;
}

export async function decryptFileChunked(
  chunks: DecryptChunk[],
  key: CryptoKey,
  iv: ArrayBuffer,
  progressCallback?: (p: { percentage: number; bytesProcessed: number; totalBytes: number }) => void
): Promise<ArrayBuffer> {
  const decryptedChunks: Uint8Array[] = [];
  let processedBytes = 0;
  const totalBytes = chunks.reduce((sum, chunk) => sum + chunk.size, 0);

  for (const chunk of chunks) {
    const encryptedData = Base64.decode(chunk.data);
    const decrypted = await window.crypto.subtle.decrypt(
      { name: 'AES-GCM', iv, additionalData: new TextEncoder().encode(String(chunk.offset)) },
      key,
      encryptedData
    );
    decryptedChunks.push(new Uint8Array(decrypted));
    processedBytes += chunk.size;
    if (progressCallback) {
      progressCallback({
        percentage: Math.round((processedBytes / totalBytes) * 100),
        bytesProcessed: processedBytes,
        totalBytes
      });
    }
  }

  const totalLength = decryptedChunks.reduce((sum, c) => sum + c.length, 0);
  const combined = new Uint8Array(totalLength);
  let offset = 0;
  for (const chunk of decryptedChunks) {
    combined.set(chunk, offset);
    offset += chunk.length;
  }
  return combined.buffer;
}

async function getDecryptionKey(
  keyBase64: string | null,
  password: string,
  passwordSaltBase64: string
): Promise<CryptoKey> {
  if (password) {
    if (!passwordSaltBase64) {
      throw new Error('Password salt is missing.');
    }
    const salt = Base64.decode(passwordSaltBase64);
    const passwordKey = await window.crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(password),
      { name: 'PBKDF2' },
      false,
      ['deriveKey']
    );
    return window.crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt,
        iterations: 100000,
        hash: 'SHA-256'
      },
      passwordKey,
      { name: 'AES-GCM', length: 256 },
      false,
      ['decrypt']
    );
  } else {
    if (!keyBase64) {
      const pathParts = window.location.pathname.replace(/\/+$/, '').substring(1).split('/');
      if (pathParts.length > 1) {
        keyBase64 = pathParts[1];
      }
      if (!keyBase64 && window.location.search) {
        const params = new URLSearchParams(window.location.search);
        keyBase64 = params.get('key');
      }
      if (!keyBase64) {
        const pathId = window.location.pathname.replace(/\/+$/, '').substring(1);
        const parts = pathId.split('.');
        if (parts.length > 1) {
          keyBase64 = parts[1];
        }
      }
      if (!keyBase64) {
        throw new Error('No decryption key found in URL. This message may require a password.');
      }
    }
    keyBase64 = keyBase64.replace(/-/g, '+').replace(/_/g, '/');
    const rawKey = Base64.decode(keyBase64);
    return window.crypto.subtle.importKey('raw', rawKey, { name: 'AES-GCM', length: 256 }, false, ['decrypt']);
  }
}

const Base64 = {
  encode(arrayBuffer: ArrayBuffer): string {
    const bytes = new Uint8Array(arrayBuffer);
    const chunkSize = 0x8000;
    if (bytes.length <= chunkSize) {
      return btoa(String.fromCharCode.apply(null, bytes as any));
    }
    let result = '';
    for (let i = 0; i < bytes.length; i += chunkSize) {
      const chunk = bytes.subarray(i, i + chunkSize);
      result += String.fromCharCode.apply(null, chunk as any);
    }
    return btoa(result);
  },

  decode(base64: string): ArrayBuffer {
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
  }
};
