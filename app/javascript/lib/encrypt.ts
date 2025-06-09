// Web Crypto API wrapper for encryption
import CSRFHelper from './csrf-helper';
import { ProgressCallback, CancelToken } from '../types/crypto.types';

export async function encryptMessage(
  message: string,
  ttl: number,
  views: number,
  password: string = '',
  burnAfterReading: boolean = false
): Promise<string> {
  try {
    const key = await generateEncryptionKey(password);
    const iv = window.crypto.getRandomValues(new Uint8Array(12));
    const encrypted = await encryptData(message, key.key, iv);

    const payload: any = {
      ciphertext: Base64.encode(encrypted),
      nonce: Base64.encode(iv),
      ttl,
      views,
      password_protected: !!password,
      burn_after_reading: burnAfterReading
    };

    if (password) {
      payload.password_salt = Base64.encode(key.salt!);
    }

    const response = await CSRFHelper.fetchWithCSRF('/encrypt', {
      method: 'POST',
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Failed to create encrypted message: ${response.status} ${response.statusText}`);
    }

    const data = await response.json();

    let link = window.location.origin + '/' + data.id;
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

export async function encryptFiles(
  files: File[],
  message: string,
  ttl: number,
  views: number,
  password: string = '',
  burnAfterReading: boolean = false,
  progressCallback: ProgressCallback | null = null,
  cancelToken: CancelToken | null = null
): Promise<string> {
  try {
    const totalSteps = files.length + 3;
    let currentStep = 0;
    const totalSize = files.reduce((sum, f) => sum + f.size, 0);
    let processedBytes = 0;
    const startTime = performance.now();

    const updateProgress = (status: string, details: string = ''): void => {
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

    const payload: any = {
      nonce: Base64.encode(iv),
      ttl,
      views,
      password_protected: !!password,
      burn_after_reading: burnAfterReading,
      files: [] as any[]
    };

    if (password) {
      payload.password_salt = Base64.encode(key.salt!);
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
      } catch (fileError: any) {
        throw new Error(`Failed to process file "${file.name}": ${fileError.message}`);
      }
    }

    updateProgress('Uploading encrypted data...');
    const response = await CSRFHelper.fetchWithCSRF('/encrypt', {
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

interface EncryptionKey {
  key: CryptoKey;
  salt?: Uint8Array;
}

async function generateEncryptionKey(password: string = ''): Promise<EncryptionKey> {
  try {
    if (password) {
      const salt = window.crypto.getRandomValues(new Uint8Array(16));
      const passwordKey = await window.crypto.subtle.importKey(
        'raw',
        new TextEncoder().encode(password),
        { name: 'PBKDF2' },
        false,
        ['deriveKey']
      );
      const key = await window.crypto.subtle.deriveKey(
        {
          name: 'PBKDF2',
          salt,
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
      const key = await window.crypto.subtle.generateKey({ name: 'AES-GCM', length: 256 }, true, ['encrypt']);
      return { key };
    }
  } catch (error) {
    throw error;
  }
}

async function encryptData(data: string | ArrayBuffer, key: CryptoKey, iv: Uint8Array): Promise<ArrayBuffer> {
  try {
    let dataBuffer: Uint8Array;
    if (typeof data === 'string') {
      dataBuffer = new TextEncoder().encode(data);
    } else {
      dataBuffer = new Uint8Array(data);
    }
    const encrypted = await window.crypto.subtle.encrypt({ name: 'AES-GCM', iv }, key, dataBuffer);
    return encrypted;
  } catch (error) {
    throw error;
  }
}

function readFileAsArrayBuffer(file: File): Promise<ArrayBuffer> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      resolve(reader.result as ArrayBuffer);
    };
    reader.onerror = () => {
      reject(new Error(`Failed to read file: ${file.name}`));
    };
    reader.readAsArrayBuffer(file);
  });
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

export default {
  encryptMessage,
  encryptFiles
};
