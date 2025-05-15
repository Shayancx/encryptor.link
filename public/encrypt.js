/**
 * Encrypts a message using AES-GCM and posts it to the server
 * @param {string} message - The plaintext message to encrypt
 * @param {number} ttl - Time to live in seconds
 * @param {number} views - Number of times the message can be viewed
 * @returns {Promise<string>} - The URL to access the encrypted message
 */
export async function encryptMessage(message, ttl, views) {
  try {
    console.log("Starting message encryption process");

    // Generate a random key
    const key = await window.crypto.subtle.generateKey(
      {
        name: "AES-GCM",
        length: 256
      },
      true,
      ["encrypt", "decrypt"]
    );

    // Export the key to raw format
    const rawKey = await window.crypto.subtle.exportKey("raw", key);
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
        views: views
      })
    });

    if (!response.ok) {
      throw new Error('Server error: ' + response.status);
    }

    const data = await response.json();

    // Create URL with the ID and key in the fragment
    const baseUrl = window.location.origin;
    return `${baseUrl}/${data.id}#${data.id}.${keyBase64}`;
  } catch (error) {
    console.error('Encryption error:', error);
    throw error;
  }
}

/**
 * Encrypts multiple files and optional message using AES-GCM and posts it to the server
 * @param {File[]} files - The files to encrypt
 * @param {string} message - Optional message to include
 * @param {number} ttl - Time to live in seconds
 * @param {number} views - Number of times the files can be viewed
 * @returns {Promise<string>} - The URL to access the encrypted files
 */
export async function encryptFiles(files, message, ttl, views) {
  try {
    console.log("Starting multi-file encryption process", {
      fileCount: files.length,
      messageLength: message?.length || 0
    });

    // Generate a random key
    const key = await window.crypto.subtle.generateKey(
      {
        name: "AES-GCM",
        length: 256
      },
      true,
      ["encrypt", "decrypt"]
    );

    // Export the key to raw format
    const rawKey = await window.crypto.subtle.exportKey("raw", key);
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

    // Encrypt each file
    const encryptedFiles = [];
    for (const file of files) {
      console.log(`Encrypting file: ${file.name} (${formatFileSize(file.size)})`);

      // Read file as ArrayBuffer
      const fileArrayBuffer = await readFileAsArrayBuffer(file);

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
        size: file.size
      });

      console.log(`File encrypted: ${file.name}`);
    }

    console.log("All files encrypted, sending to server");

    // Post encrypted data to server
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
        files: encryptedFiles
      })
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Server response error:", errorText);
      throw new Error('Server error: ' + response.status);
    }

    const data = await response.json();
    console.log("Server response:", data);

    // Create URL with the ID and key in the fragment
    const baseUrl = window.location.origin;
    return `${baseUrl}/${data.id}#${data.id}.${keyBase64}`;
  } catch (error) {
    console.error('File encryption error:', error);
    throw error;
  }
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
