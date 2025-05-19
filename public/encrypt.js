/**
 * Encrypts a message using AES-GCM and posts it to the server
 * @param {string} message - The plaintext message to encrypt
 * @param {number} ttl - Time to live in seconds
 * @param {number} views - Number of times the message can be viewed
 * @param {string} password - Optional password for additional protection
 * @returns {Promise<string>} - The URL to access the encrypted message
 */
export async function encryptMessage(message, ttl, views, password = '') {
  try {
    
    const usePassword = !!(password && password.trim().length > 0);

    // For password-based encryption, we'll use PBKDF2
    let key, rawKey, salt, saltBase64;
    
    if (usePassword) {
      // Generate a salt for PBKDF2
      salt = window.crypto.getRandomValues(new Uint8Array(16));
      saltBase64 = arrayBufferToBase64(salt);
      
      // Derive key from password using PBKDF2
      const passwordKey = await deriveKeyFromPassword(password, salt);
      
      // Use the derived key
      key = passwordKey;
      rawKey = await window.crypto.subtle.exportKey("raw", key);
    } else {
      // Generate a random key for non-password encryption
      key = await window.crypto.subtle.generateKey(
        {
          name: "AES-GCM",
          length: 256
        },
        true,
        ["encrypt", "decrypt"]
      );
      rawKey = await window.crypto.subtle.exportKey("raw", key);
    }
    
    const keyBase64 = arrayBufferToBase64(rawKey);

    // Generate a random IV
    const iv = window.crypto.getRandomValues(new Uint8Array(12));
    const ivBase64 = arrayBufferToBase64(iv);

    // Encode the message as UTF-8
    const encodedMessage = new TextEncoder().encode(message);

    // Encrypt the message
    const ciphertext = await window.crypto.subtle.encrypt(
      {
        name: "AES-GCM",
        iv: iv
      },
      key,
      encodedMessage
    );

    // Convert ciphertext to Base64
    const ciphertextBase64 = arrayBufferToBase64(ciphertext);

    // Post encrypted data to server
    console.log("Sending to server:", {
      passwordProtected: usePassword,
      hasSalt: !!saltBase64
    });
    
    const response = await fetch('/encrypt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': getCSRFToken()
      },
      body: JSON.stringify({
        ciphertext: ciphertextBase64,
        nonce: ivBase64,
        ttl: ttl,
        views: views,
        password_protected: usePassword,
        password_salt: usePassword ? saltBase64 : null
      })
    });

    if (!response.ok) {
      throw new Error('Server error: ' + response.status);
    }

    const data = await response.json();
    

    // Create URL with the ID and key in the fragment
    const baseUrl = window.location.origin;
    if (usePassword) {
      // For password protected links, we don't include the key in the URL
      // The recipient will need to enter the password
      return `${baseUrl}/${data.id}#${data.id}`;
    } else {
      // For non-password links, include key in URL fragment
      return `${baseUrl}/${data.id}#${data.id}.${keyBase64}`;
    }
  } catch (error) {
    console.error('Encryption error:', error);
    throw error;
  }
}

/**
 * Derives a cryptographic key from a password using PBKDF2
 * @param {string} password - The password
 * @param {ArrayBuffer} salt - Salt for PBKDF2
 * @returns {Promise<CryptoKey>} - The derived key
 */
async function deriveKeyFromPassword(password, salt) {
  // First, create a key from the password
  const passwordKey = await window.crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(password),
    { name: "PBKDF2" },
    false,
    ["deriveKey"]
  );
  
  // Then derive an AES-GCM key using PBKDF2
  return window.crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt: salt,
      iterations: 100000,
      hash: "SHA-256"
    },
    passwordKey,
    {
      name: "AES-GCM",
      length: 256
    },
    true,
    ["encrypt", "decrypt"]
  );
}

/**
 * Encrypts multiple files and optional message using AES-GCM and posts it to the server
 * @param {File[]} files - The files to encrypt
 * @param {string} message - Optional message to include
 * @param {number} ttl - Time to live in seconds
 * @param {number} views - Number of times the files can be viewed
 * @param {string} password - Optional password for additional protection
 * @returns {Promise<string>} - The URL to access the encrypted files
 */
export async function encryptFiles(files, message, ttl, views, password = '') {
  try {
    console.log("Starting multi-file encryption process", {
      fileCount: files.length,
      messageLength: message?.length || 0,
      passwordProtected: password && password.trim().length > 0
    });

    const usePassword = !!(password && password.trim().length > 0);
    let key, rawKey, salt, saltBase64;
    
    if (usePassword) {
      // Generate a salt for PBKDF2
      salt = window.crypto.getRandomValues(new Uint8Array(16));
      saltBase64 = arrayBufferToBase64(salt);
      
      // Derive key from password using PBKDF2
      const passwordKey = await deriveKeyFromPassword(password, salt);
      
      // Use the derived key
      key = passwordKey;
      rawKey = await window.crypto.subtle.exportKey("raw", key);
    } else {
      // Generate a random key for non-password encryption
      key = await window.crypto.subtle.generateKey(
        {
          name: "AES-GCM",
          length: 256
        },
        true,
        ["encrypt", "decrypt"]
      );
      rawKey = await window.crypto.subtle.exportKey("raw", key);
    }
    
    const keyBase64 = arrayBufferToBase64(rawKey);

    // Generate a random IV
    const iv = window.crypto.getRandomValues(new Uint8Array(12));
    const ivBase64 = arrayBufferToBase64(iv);

    // Encrypt the message if provided
    let ciphertextBase64 = '';
    if (message && message.trim()) {
      const encodedMessage = new TextEncoder().encode(message);
      const ciphertext = await window.crypto.subtle.encrypt(
        {
          name: "AES-GCM",
          iv: iv
        },
        key,
        encodedMessage
      );
      ciphertextBase64 = arrayBufferToBase64(ciphertext);
    }

    // Calculate hash for each file for integrity verification
    const encryptedFiles = [];
    for (const file of files) {
      

      // Read file as ArrayBuffer
      const fileArrayBuffer = await readFileAsArrayBuffer(file);
      
      // Calculate file hash
      const fileHash = await calculateFileHash(fileArrayBuffer);

      // Encrypt the file
      const encryptedFile = await window.crypto.subtle.encrypt(
        {
          name: "AES-GCM",
          iv: iv
        },
        key,
        fileArrayBuffer
      );

      // Convert to Base64
      const fileDataBase64 = arrayBufferToBase64(encryptedFile);

      // Add to encrypted files array
      encryptedFiles.push({
        data: fileDataBase64,
        name: file.name,
        type: file.type,
        size: file.size,
        hash: fileHash
      });

      
    }

    

    // Post encrypted data to server
    const response = await fetch('/encrypt', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': getCSRFToken()
      },
      body: JSON.stringify({
        ciphertext: ciphertextBase64 || "",
        nonce: ivBase64,
        ttl: ttl,
        views: views,
        files: encryptedFiles,
        password_protected: usePassword,
        password_salt: usePassword ? saltBase64 : null
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Server response error:", errorText);
      throw new Error('Server error: ' + response.status);
    }

    const data = await response.json();
    

    // Create URL with the ID and key in the fragment
    const baseUrl = window.location.origin;
    if (usePassword) {
      // For password protected links, we don't include the key in the URL
      
      return `${baseUrl}/${data.id}#${data.id}`;
    } else {
      // For non-password links, include key in URL fragment
      
      return `${baseUrl}/${data.id}#${data.id}.${keyBase64}`;
    }
  } catch (error) {
    console.error('File encryption error:', error);
    throw error;
  }
}

/**
 * Calculate SHA-256 hash of a file for integrity verification
 * @param {ArrayBuffer} data - The file data
 * @returns {Promise<string>} - Base64 encoded hash
 */
async function calculateFileHash(data) {
  const hashBuffer = await window.crypto.subtle.digest('SHA-256', data);
  return arrayBufferToBase64(hashBuffer);
}

/**
 * Read a file as ArrayBuffer
 * @param {File} file - The file to read
 * @returns {Promise<ArrayBuffer>} - The file contents as ArrayBuffer
 */
function readFileAsArrayBuffer(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = (e) => reject(new Error('Error reading file: ' + e.target.error));
    reader.readAsArrayBuffer(file);
  });
}

/**
 * Convert ArrayBuffer to Base64 string
 */
function arrayBufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  let binary = '';
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
}

/**
 * Get CSRF token from meta tag
 */
function getCSRFToken() {
  return document.querySelector('meta[name="csrf-token"]').getAttribute('content');
}

/**
 * Format file size
 */
function formatFileSize(bytes) {
  if (bytes < 1024) return bytes + ' bytes';
  else if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
  else if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
  else return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
}
