// Web Crypto API wrapper for decryption
async function decryptMessage(ciphertextBase64, ivBase64, keyBase64 = null, password = '', passwordSaltBase64 = '') {
  try {
    // Import or derive the key
    const key = await getDecryptionKey(keyBase64, password, passwordSaltBase64);

    // Decode the ciphertext and iv
    const ciphertext = Base64.decode(ciphertextBase64);
    const iv = Base64.decode(ivBase64);

    // Decrypt using AES-GCM
    const decrypted = await window.crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: iv },
      key,
      ciphertext
    );

    // Convert the decrypted data to a string
    const decoder = new TextDecoder();
    return decoder.decode(decrypted);
  } catch (error) {
    console.error('Decryption error:', error);
    throw new Error('Failed to decrypt the message. The key might be incorrect.');
  }
}

// Decrypt file data
async function decryptFile(fileDataBase64, ivBase64, keyBase64 = null, password = '', passwordSaltBase64 = '') {
  try {
    // Import or derive the key
    const key = await getDecryptionKey(keyBase64, password, passwordSaltBase64);

    // Decode the file data and iv
    const fileData = Base64.decode(fileDataBase64);
    const iv = Base64.decode(ivBase64);

    // Decrypt using AES-GCM
    const decrypted = await window.crypto.subtle.decrypt(
      { name: 'AES-GCM', iv: iv },
      key,
      fileData
    );

    return decrypted;
  } catch (error) {
    console.error('File decryption error:', error);
    throw new Error('Failed to decrypt the file. The key might be incorrect.');
  }
}

// Decrypt a file that was uploaded in chunks
async function decryptFileChunked(chunks, key, iv, progressCallback = null) {
  const decryptedChunks = [];
  let processedBytes = 0;
  const totalBytes = chunks.reduce((sum, chunk) => sum + chunk.size, 0);

  for (const chunk of chunks) {
    const encryptedData = Base64.decode(chunk.data);

    const decrypted = await window.crypto.subtle.decrypt(
      {
        name: 'AES-GCM',
        iv: iv,
        additionalData: new TextEncoder().encode(String(chunk.offset))
      },
      key,
      encryptedData
    );

    decryptedChunks.push(new Uint8Array(decrypted));
    processedBytes += chunk.size;

    if (progressCallback) {
      progressCallback({
        percentage: Math.round((processedBytes / totalBytes) * 100),
        bytesProcessed: processedBytes,
        totalBytes: totalBytes
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

// Get decryption key - either from URL or derive from password
async function getDecryptionKey(keyBase64, password, passwordSaltBase64) {
  // For password-protected content
  if (password) {
    if (!passwordSaltBase64) {
      throw new Error('Password salt is missing.');
    }

    // Decode the salt
    const salt = Base64.decode(passwordSaltBase64);

    // Convert password to a key using PBKDF2
    const passwordKey = await window.crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(password),
      { name: 'PBKDF2' },
      false,
      ['deriveKey']
    );

    // Derive the actual encryption key
    return window.crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt: salt,
        iterations: 100000,
        hash: 'SHA-256'
      },
      passwordKey,
      { name: 'AES-GCM', length: 256 },
      false,
      ['decrypt']
    );
  }
  // For non-password protected content
  else {
    if (!keyBase64) {
      // Try to extract key from URL path if it's not in the fragment
      const pathParts = window.location.pathname.substring(1).split('/');
      if (pathParts.length > 1) {
        keyBase64 = pathParts[1];
      }

      // If still no key, check if it's in a different format in the URL
      if (!keyBase64 && window.location.search) {
        const params = new URLSearchParams(window.location.search);
        keyBase64 = params.get('key');
      }

      // Last attempt - check if the key is appended to the ID with a dot
      if (!keyBase64) {
        const pathId = window.location.pathname.substring(1);
        const parts = pathId.split('.');
        if (parts.length > 1) {
          keyBase64 = parts[1];
        }
      }

      if (!keyBase64) {
        throw new Error('No decryption key found in URL. This message may require a password.');
      }
    }

    // Clean up any URL-safe base64 modifications
    keyBase64 = keyBase64.replace(/-/g, '+').replace(/_/g, '/');

    // Decode the key
    const rawKey = Base64.decode(keyBase64);

    // Import the key
    return window.crypto.subtle.importKey(
      'raw',
      rawKey,
      { name: 'AES-GCM', length: 256 },
      false,
      ['decrypt']
    );
  }
}

// Optimized Base64 utility object that handles large files efficiently
const Base64 = {
  encode: function(arrayBuffer) {
    // For large files, use chunked encoding to avoid call stack limits
    const bytes = new Uint8Array(arrayBuffer);
    const chunkSize = 0x8000; // 32KB chunks

    if (bytes.length <= chunkSize) {
      // For small files, use the original method
      return btoa(String.fromCharCode.apply(null, bytes));
    }

    // For large files, process in chunks
    let result = '';
    for (let i = 0; i < bytes.length; i += chunkSize) {
      const chunk = bytes.subarray(i, i + chunkSize);
      result += String.fromCharCode.apply(null, chunk);
    }
    return btoa(result);
  },

  decode: function(base64) {
    const binaryString = atob(base64);
    const bytes = new Uint8Array(binaryString.length);
    for (let i = 0; i < binaryString.length; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
  }
};

// Export the functions
export { decryptMessage, decryptFile, decryptFileChunked };
