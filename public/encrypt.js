// Web Crypto API wrapper for encryption
async function encryptMessage(message, ttl, views, password = '') {
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
      password_protected: !!password
    };

    // Add password salt if password is provided
    if (password) {
      payload.password_salt = Base64.encode(key.salt);
    }

    // Send the encrypted data to the server
    const response = await fetch('/encrypt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
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

// Encrypt multiple files
async function encryptFiles(files, message, ttl, views, password = '') {
  try {
    // Generate a random encryption key
    const key = await generateEncryptionKey(password);

    // Generate a random IV
    const iv = window.crypto.getRandomValues(new Uint8Array(12));

    // Create API payload
    const payload = {
      nonce: Base64.encode(iv),
      ttl: ttl,
      views: views,
      password_protected: !!password,
      files: []
    };

    // Add password salt if password is provided
    if (password) {
      payload.password_salt = Base64.encode(key.salt);
    }

    // Encrypt message if present
    if (message && message.trim() !== '') {
      const encryptedMessage = await encryptData(message, key.key, iv);
      payload.ciphertext = Base64.encode(encryptedMessage);
    } else {
      payload.ciphertext = '';
    }

    // Process each file
    for (let i = 0; i < files.length; i++) {
      const file = files[i];

      try {
        // Read the file as an ArrayBuffer
        const fileData = await readFileAsArrayBuffer(file);

        // Encrypt the file data
        const encryptedFile = await encryptData(fileData, key.key, iv);

        // Encode to Base64
        const encodedFile = Base64.encode(encryptedFile);

        // Add the encrypted file to the payload
        payload.files.push({
          data: encodedFile,
          name: file.name,
          type: file.type || 'application/octet-stream',
          size: file.size
        });
      } catch (fileError) {
        throw new Error(`Failed to process file "${file.name}": ${fileError.message}`);
      }
    }

    // Send the encrypted data to the server
    const response = await fetch('/encrypt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Failed to create encrypted message with files: ${response.status} ${response.statusText} - ${errorText}`);
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
