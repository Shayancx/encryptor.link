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
      throw new Error('Failed to create encrypted message');
    }

    const data = await response.json();

    // Generate link with the key in the fragment
    let link = window.location.origin + '/' + data.id;

    // For non-password protected content, add the key to the fragment
    if (!password) {
      link += '#' + Base64.encode(await window.crypto.subtle.exportKey('raw', key.key));
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
    for (const file of files) {
      // Read the file as an ArrayBuffer
      const fileData = await readFileAsArrayBuffer(file);

      // Encrypt the file data
      const encryptedFile = await encryptData(fileData, key.key, iv);

      // Add the encrypted file to the payload
      payload.files.push({
        data: Base64.encode(encryptedFile),
        name: file.name,
        type: file.type || 'application/octet-stream',
        size: file.size
      });
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
      throw new Error('Failed to create encrypted message with files');
    }

    const data = await response.json();

    // Generate link with the key in the fragment
    let link = window.location.origin + '/' + data.id;

    // For non-password protected content, add the key to the fragment
    if (!password) {
      link += '#' + Base64.encode(await window.crypto.subtle.exportKey('raw', key.key));
    }

    return link;
  } catch (error) {
    console.error('File encryption error:', error);
    throw error;
  }
}

// Generate an encryption key
async function generateEncryptionKey(password = '') {
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
}

// Encrypt data with AES-GCM
async function encryptData(data, key, iv) {
  // Convert string to ArrayBuffer if needed
  let dataBuffer;
  if (typeof data === 'string') {
    dataBuffer = new TextEncoder().encode(data);
  } else {
    dataBuffer = new Uint8Array(data);
  }

  // Encrypt using AES-GCM
  return window.crypto.subtle.encrypt(
    { name: 'AES-GCM', iv: iv },
    key,
    dataBuffer
  );
}

// Read a file as ArrayBuffer
function readFileAsArrayBuffer(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error('Failed to read file'));
    reader.readAsArrayBuffer(file);
  });
}

// Base64 utility object
const Base64 = {
  encode: function(arrayBuffer) {
    return btoa(String.fromCharCode.apply(null, new Uint8Array(arrayBuffer)));
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
export { encryptMessage, encryptFiles };
