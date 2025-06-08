// app/javascript/lib/decrypt.js
async function decryptMessage(ciphertextBase64, ivBase64, keyBase64 = null, password = "", passwordSaltBase64 = "") {
  try {
    const key = await getDecryptionKey(keyBase64, password, passwordSaltBase64);
    const ciphertext = Base64.decode(ciphertextBase64);
    const iv = Base64.decode(ivBase64);
    const decrypted = await window.crypto.subtle.decrypt(
      { name: "AES-GCM", iv },
      key,
      ciphertext
    );
    const decoder = new TextDecoder();
    return decoder.decode(decrypted);
  } catch (error) {
    console.error("Decryption error:", error);
    throw new Error("Failed to decrypt the message. The key might be incorrect.");
  }
}
async function decryptFile(fileDataBase64, ivBase64, keyBase64 = null, password = "", passwordSaltBase64 = "") {
  try {
    const key = await getDecryptionKey(keyBase64, password, passwordSaltBase64);
    const fileData = Base64.decode(fileDataBase64);
    const iv = Base64.decode(ivBase64);
    const decrypted = await window.crypto.subtle.decrypt(
      { name: "AES-GCM", iv },
      key,
      fileData
    );
    return decrypted;
  } catch (error) {
    console.error("File decryption error:", error);
    throw new Error("Failed to decrypt the file. The key might be incorrect.");
  }
}
async function getDecryptionKey(keyBase64, password, passwordSaltBase64) {
  if (password) {
    if (!passwordSaltBase64) {
      throw new Error("Password salt is missing.");
    }
    const salt = Base64.decode(passwordSaltBase64);
    const passwordKey = await window.crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(password),
      { name: "PBKDF2" },
      false,
      ["deriveKey"]
    );
    return window.crypto.subtle.deriveKey(
      {
        name: "PBKDF2",
        salt,
        iterations: 1e5,
        hash: "SHA-256"
      },
      passwordKey,
      { name: "AES-GCM", length: 256 },
      false,
      ["decrypt"]
    );
  } else {
    if (!keyBase64) {
      const pathParts = window.location.pathname.substring(1).split("/");
      if (pathParts.length > 1) {
        keyBase64 = pathParts[1];
      }
      if (!keyBase64 && window.location.search) {
        const params = new URLSearchParams(window.location.search);
        keyBase64 = params.get("key");
      }
      if (!keyBase64) {
        const pathId = window.location.pathname.substring(1);
        const parts = pathId.split(".");
        if (parts.length > 1) {
          keyBase64 = parts[1];
        }
      }
      if (!keyBase64) {
        throw new Error("No decryption key found in URL. This message may require a password.");
      }
    }
    keyBase64 = keyBase64.replace(/-/g, "+").replace(/_/g, "/");
    const rawKey = Base64.decode(keyBase64);
    return window.crypto.subtle.importKey(
      "raw",
      rawKey,
      { name: "AES-GCM", length: 256 },
      false,
      ["decrypt"]
    );
  }
}
var Base64 = {
  encode: function(arrayBuffer) {
    const bytes = new Uint8Array(arrayBuffer);
    const chunkSize = 32768;
    if (bytes.length <= chunkSize) {
      return btoa(String.fromCharCode.apply(null, bytes));
    }
    let result = "";
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
export {
  decryptFile,
  decryptMessage
};
//# sourceMappingURL=decrypt.js.map
