/**
 * Decrypts a message using AES-GCM
 * @param {string} ciphertextBase64 - The base64-encoded encrypted message
 * @param {string} ivBase64 - The base64-encoded IV
 * @param {string} keyBase64 - The base64-encoded encryption key
 * @returns {Promise<string>} - The decrypted message
 */
export async function decryptMessage(ciphertextBase64, ivBase64, keyBase64) {
  try {
    console.log("Starting message decryption");

    // Convert Base64 to ArrayBuffer
    const ciphertext = base64ToArrayBuffer(ciphertextBase64);
    const iv = base64ToArrayBuffer(ivBase64);
    const rawKey = base64ToArrayBuffer(keyBase64);

    // Import the key
    const key = await window.crypto.subtle.importKey(
      "raw",
      rawKey,
      {
        name: "AES-GCM",
        length: 256
      },
      false,
      ["decrypt"]
    );

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
 * Decrypts a file using AES-GCM
 * @param {string} fileDataBase64 - The base64-encoded encrypted file
 * @param {string} ivBase64 - The base64-encoded IV
 * @param {string} keyBase64 - The base64-encoded encryption key
 * @returns {Promise<ArrayBuffer>} - The decrypted file as ArrayBuffer
 */
export async function decryptFile(fileDataBase64, ivBase64, keyBase64) {
  try {
    console.log("Starting file decryption");

    // Convert Base64 to ArrayBuffer
    const fileData = base64ToArrayBuffer(fileDataBase64);
    const iv = base64ToArrayBuffer(ivBase64);
    const rawKey = base64ToArrayBuffer(keyBase64);

    console.log("Converted Base64 to ArrayBuffer", {
      fileDataSize: fileData.byteLength,
      ivSize: iv.byteLength,
      keySize: rawKey.byteLength
    });

    // Import the key
    const key = await window.crypto.subtle.importKey(
      "raw",
      rawKey,
      {
        name: "AES-GCM",
        length: 256
      },
      false,
      ["decrypt"]
    );

    console.log("Key imported successfully");

    // Decrypt the file
    console.log("Decrypting file data...");
    const decrypted = await window.crypto.subtle.decrypt(
      {
        name: "AES-GCM",
        iv: iv
      },
      key,
      fileData
    );

    console.log("File decrypted successfully", { decryptedSize: decrypted.byteLength });
    return decrypted;
  } catch (error) {
    console.error('File decryption error:', error);
    throw error;
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
