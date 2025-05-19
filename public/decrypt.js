/**
 * Decrypts a message using AES-GCM
 * @param {string} ciphertextBase64 - The base64-encoded encrypted message
 * @param {string} ivBase64 - The base64-encoded IV
 * @param {string} keyBase64 - The base64-encoded encryption key
 * @returns {Promise<string>} - The decrypted message
 */
export async function decryptMessage(ciphertextBase64, ivBase64, keyBase64, password = '', saltBase64 = '') {
  try {
    console.log("Starting message decryption with:", {
      hasPassword: !!password,
      hasSalt: !!saltBase64,
      hasKey: !!keyBase64
    });

    // Convert Base64 to ArrayBuffer
    const ciphertext = base64ToArrayBuffer(ciphertextBase64);
    const iv = base64ToArrayBuffer(ivBase64);

    let key;

    if (password && saltBase64) {

      // If we have a password and salt, derive the key from it
      const salt = base64ToArrayBuffer(saltBase64);
      key = await deriveKeyFromPassword(password, salt);
    } else {

      // Otherwise use the provided key
      const rawKey = base64ToArrayBuffer(keyBase64);
      // Import the key
      key = await window.crypto.subtle.importKey(
        "raw",
        rawKey,
        {
          name: "AES-GCM",
          length: 256
        },
        false,
        ["decrypt"]
      );
    }

    // Decrypt the ciphertext
    const decrypted = await window.crypto.subtle.decrypt(
      {
        name: "AES-GCM",
        iv: iv
      },
      key,
      ciphertext
    );

    // Decode the result as UTF-8
    return new TextDecoder().decode(decrypted);
  } catch (error) {
    console.error('Message decryption error:', error);
    // Return empty string for empty messages
    if (ciphertextBase64 === "" || !ciphertextBase64) {
      return "";
    }
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
    ["decrypt"]
  );
}

/**
 * Decrypts a file using AES-GCM
 * @param {string} fileDataBase64 - The base64-encoded encrypted file
 * @param {string} ivBase64 - The base64-encoded IV
 * @param {string} keyBase64 - The base64-encoded encryption key
 * @param {string} password - Optional password if the content is password-protected
 * @param {string} saltBase64 - Base64-encoded salt for password-based decryption
 * @returns {Promise<ArrayBuffer>} - The decrypted file as ArrayBuffer
 */
export async function decryptFile(fileDataBase64, ivBase64, keyBase64, password = '', saltBase64 = '') {
  try {


    // Convert Base64 to ArrayBuffer
    const fileData = base64ToArrayBuffer(fileDataBase64);
    const iv = base64ToArrayBuffer(ivBase64);

    let key;

    if (password && saltBase64) {
      // If we have a password and salt, derive the key from it
      const salt = base64ToArrayBuffer(saltBase64);
      key = await deriveKeyFromPassword(password, salt);
    } else {
      // Otherwise use the provided key
      const rawKey = base64ToArrayBuffer(keyBase64);
      // Import the key
      key = await window.crypto.subtle.importKey(
        "raw",
        rawKey,
        {
          name: "AES-GCM",
          length: 256
        },
        false,
        ["decrypt"]
      );
    }



    // Decrypt the file

    const decrypted = await window.crypto.subtle.decrypt(
      {
        name: "AES-GCM",
        iv: iv
      },
      key,
      fileData
    );


    return decrypted;
  } catch (error) {
    console.error('File decryption error:', error);
    throw error;
  }
}

/**
 * Verify the integrity of a file by checking its hash
 * @param {ArrayBuffer} fileData - The decrypted file data
 * @param {string} expectedHashBase64 - The expected hash in Base64
 * @returns {Promise<boolean>} - True if the hash matches
 */
export async function verifyFileIntegrity(fileData, expectedHashBase64) {
  try {
    // Calculate the hash of the decrypted file
    const hashBuffer = await window.crypto.subtle.digest('SHA-256', fileData);
    const actualHashBase64 = arrayBufferToBase64(hashBuffer);

    // Compare with the expected hash
    return actualHashBase64 === expectedHashBase64;
  } catch (error) {
    console.error('File integrity verification error:', error);
    return false;
  }
}

/**
 * Convert Base64 string to ArrayBuffer
 */
function base64ToArrayBuffer(base64) {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
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
