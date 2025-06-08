// Web Crypto API wrapper for encryption

// Chunk constants for streaming processing
const CHUNK_SIZE = 5 * 1024 * 1024; // 5MB chunks for processing
const UPLOAD_CHUNK_SIZE = 10 * 1024 * 1024; // 10MB chunks for uploading
async function encryptMessage(message, ttl, views, password = '', burnAfterReading = false) {
  try {
    // Generate a random encryption key
    const key = await generateEncryptionKey(password);

    // Generate a random IV
    const iv = window.crypto.getRandomValues(new Uint8Array(12));

    // Encrypt the message
    const encrypted = await encryptData(message, key.key, iv);

    // Prepare API payload
    const payload = {
      ciphertext: Base64.encode(encrypted),
      nonce: Base64.encode(iv),
      ttl: ttl,
      views: views,
      password_protected: !!password,
      burn_after_reading: burnAfterReading
    };

    // Add password salt if password is provided
    if (password) {
      payload.password_salt = Base64.encode(key.salt);
    }

    // Send the encrypted data to the server with CSRF protection
    const response = await CSRFHelper.fetchWithCSRF('/encrypt', {
      method: 'POST',
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Failed to create encrypted message: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    // Generate link with the key in the fragment
    let link = window.location.origin + '/' + data.id;

    // For non-password protected content, add the key to the fragment
    if (!password) {
      const exportedKey = await window.crypto.subtle.exportKey('raw', key.key);
      const keyBase64 = Base64.encode(exportedKey);
      link += '#' + keyBase64;
    }

    return link;
  } catch (error) {
    console.error('Encryption error:', error);
    throw error;
  }
}

// Encrypt a file in chunks using streaming readers
async function encryptFileChunked(file, key, iv, progressCallback = null) {
  const chunks = [];
  const reader = file.stream().getReader();
  const encoder = new TextEncoder();
  let offset = 0;

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const encryptedChunk = await window.crypto.subtle.encrypt(
        {
          name: 'AES-GCM',
          iv: iv,
          additionalData: encoder.encode(String(offset))
        },
        key,
        value
      );

      chunks.push({ offset: offset, data: encryptedChunk, size: value.byteLength });
      offset += value.byteLength;

      if (progressCallback) {
        progressCallback({
          file: file.name,
          bytesProcessed: offset,
          totalBytes: file.size,
          percentage: Math.round((offset / file.size) * 100)
        });
      }
    }
  } finally {
    reader.releaseLock();
  }

  return chunks;
}

// Encrypt multiple files with progress reporting and cancellation support
async function encryptFiles(
  files,
  message,
  ttl,
  views,
  password = '',
  burnAfterReading = false,
  progressCallback = null,
  cancelToken = null
) {
  try {
    const totalSteps = files.length + 3; // key generation, message, upload
    let currentStep = 0;
    const totalSize = files.reduce((sum, f) => sum + f.size, 0);
    let processedBytes = 0;
    const startTime = performance.now();

    const updateProgress = (status, details = '') => {
      currentStep++;
      const percentage = Math.round((currentStep / totalSteps) * 100);
      const elapsed = (performance.now() - startTime) / 1000;
      const speed = elapsed > 0 ? processedBytes / (1024 * 1024 * elapsed) : 0;
      const remaining = totalSize - processedBytes;
      const eta = speed > 0 ? remaining / (1024 * 1024 * speed) : 0;
      if (progressCallback) {
        progressCallback({ percentage, status, details, speed, eta });
      }
      if (cancelToken && cancelToken.canceled) {
        throw new Error('Encryption cancelled');
      }
    };

    updateProgress('Generating encryption key...');
    const key = await generateEncryptionKey(password);

    const iv = window.crypto.getRandomValues(new Uint8Array(12));

    const payload = {
      nonce: Base64.encode(iv),
      ttl: ttl,
      views: views,
      password_protected: !!password,
      burn_after_reading: burnAfterReading,
      files: [],
      chunked_files: [],
      session_id: crypto.randomUUID()
    };

    if (password) {
      payload.password_salt = Base64.encode(key.salt);
    }

    if (message && message.trim() !== '') {
      updateProgress('Encrypting message...');
      const encryptedMessage = await encryptData(message, key.key, iv);
      payload.ciphertext = Base64.encode(encryptedMessage);
    } else {
      payload.ciphertext = '';
    }

    for (const file of files) {
      updateProgress(`Encrypting file`, file.name);
      try {
        if (file.size <= CHUNK_SIZE) {
          const fileData = await readFileAsArrayBuffer(file);
          const encryptedFile = await encryptData(fileData, key.key, iv);
          const encodedFile = Base64.encode(encryptedFile);
          payload.files.push({
            data: encodedFile,
            name: file.name,
            type: file.type || 'application/octet-stream',
            size: file.size
          });
          processedBytes += file.size;
        } else {
          const fileMetadata = {
            name: file.name,
            type: file.type || 'application/octet-stream',
            size: file.size,
            chunks: []
          };

          const encryptedChunks = await encryptFileChunked(
            file,
            key.key,
            iv,
            (progress) => {
              if (progressCallback) {
                progressCallback({
                  status: `Encrypting ${file.name}`,
                  fileProgress: progress.percentage,
                  details: `${Math.round(progress.bytesProcessed / 1024 / 1024)}MB / ${Math.round(progress.totalBytes / 1024 / 1024)}MB`
                });
              }
            }
          );

          for await (const encodedChunk of Base64.encodeChunked(encryptedChunks)) {
            const chunkResponse = await CSRFHelper.fetchWithCSRF('/encrypt/chunk', {
              method: 'POST',
              body: JSON.stringify({
                session_id: payload.session_id || crypto.randomUUID(),
                chunk: encodedChunk
              })
            });

            if (!chunkResponse.ok) throw new Error('Chunk upload failed');

            const chunkData = await chunkResponse.json();
            fileMetadata.chunks.push(chunkData.chunk_id);
            processedBytes += encodedChunk.originalSize;
          }

          payload.chunked_files.push(fileMetadata);
        }
      } catch (fileError) {
        throw new Error(`Failed to process file "${file.name}": ${fileError.message}`);
      }
    }

    updateProgress('Uploading encrypted data...');
    const response = await CSRFHelper.fetchWithCSRF('/encrypt/finalize', {
      method: 'POST',
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Upload failed: ${response.status} - ${errorText}`);
    }

    const data = await response.json();

    let link = window.location.origin + '/' + data.id;
    if (!password) {
      const exportedKey = await window.crypto.subtle.exportKey('raw', key.key);
      const keyBase64 = Base64.encode(exportedKey);
      link += '#' + keyBase64;
    }

    updateProgress('Complete!');
    return link;
  } catch (error) {
    console.error('File encryption error:', error);
    throw error;
  }
}

// Generate an encryption key
async function generateEncryptionKey(password = '') {
  try {
    if (password) {
      // Generate a random salt
      const salt = window.crypto.getRandomValues(new Uint8Array(16));

      // Convert password to a key using PBKDF2
      const passwordKey = await window.crypto.subtle.importKey(
        'raw',
        new TextEncoder().encode(password),
        { name: 'PBKDF2' },
        false,
        ['deriveKey']
      );

      // Derive the actual encryption key
      const key = await window.crypto.subtle.deriveKey(
        {
          name: 'PBKDF2',
          salt: salt,
          iterations: 100000,
          hash: 'SHA-256'
        },
        passwordKey,
        { name: 'AES-GCM', length: 256 },
        true,
        ['encrypt']
      );

      return { key, salt };
    } else {
      // Generate a random key
      const key = await window.crypto.subtle.generateKey(
        { name: 'AES-GCM', length: 256 },
        true,
        ['encrypt']
      );

      return { key };
    }
  } catch (error) {
    throw error;
  }
}

// Encrypt data with AES-GCM
async function encryptData(data, key, iv) {
  try {
    // Convert string to ArrayBuffer if needed
    let dataBuffer;
    if (typeof data === 'string') {
      dataBuffer = new TextEncoder().encode(data);
    } else {
      dataBuffer = new Uint8Array(data);
    }

    // Encrypt using AES-GCM
    const encrypted = await window.crypto.subtle.encrypt(
      { name: 'AES-GCM', iv: iv },
      key,
      dataBuffer
    );

    return encrypted;
  } catch (error) {
    throw error;
  }
}

// Read a file as ArrayBuffer
function readFileAsArrayBuffer(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = () => {
      resolve(reader.result);
    };

    reader.onerror = () => {
      const errorMsg = `Failed to read file: ${file.name}`;
      reject(new Error(errorMsg));
    };

    reader.readAsArrayBuffer(file);
  });
}

// Optimized Base64 utility object that handles large files efficiently
const Base64 = {
  encode: function(arrayBuffer) {
    try {
      // For large files, use chunked encoding to avoid call stack limits
      const bytes = new Uint8Array(arrayBuffer);
      const chunkSize = 0x8000; // 32KB chunks

      if (bytes.length <= chunkSize) {
        // For small files, use the original method
        const result = btoa(String.fromCharCode.apply(null, bytes));
        return result;
      }

      // For large files, process in chunks
      let result = '';
      for (let i = 0; i < bytes.length; i += chunkSize) {
        const chunk = bytes.subarray(i, i + chunkSize);
        result += String.fromCharCode.apply(null, chunk);
      }

      const encodedResult = btoa(result);
      return encodedResult;
    } catch (error) {
      throw new Error(`Base64 encoding failed: ${error.message}`);
    }
  },

  async *encodeChunked(chunks) {
    for (const chunk of chunks) {
      const bytes = new Uint8Array(chunk.data);
      const chunkSize = 0x8000; // 32KB chunks for base64 encoding

      let result = '';
      for (let i = 0; i < bytes.length; i += chunkSize) {
        const slice = bytes.subarray(i, Math.min(i + chunkSize, bytes.length));
        result += btoa(String.fromCharCode.apply(null, slice));
      }

      yield {
        offset: chunk.offset,
        data: result,
        originalSize: chunk.size
      };
    }
  },

  decode: function(base64) {
    try {
      const binaryString = atob(base64);
      const bytes = new Uint8Array(binaryString.length);
      for (let i = 0; i < binaryString.length; i++) {
        bytes[i] = binaryString.charCodeAt(i);
      }
      return bytes.buffer;
    } catch (error) {
      throw new Error(`Base64 decoding failed: ${error.message}`);
    }
  }
};

// Export the functions
export { encryptMessage, encryptFiles };
