import CryptoJS from 'crypto-js';
import fileDownload from 'js-file-download';
import sanitizeHtml from 'sanitize-html';
import { nanoid } from 'nanoid';
import { bufferToBase64, base64ToBuffer } from './utils';
import { EnvironmentService } from '@/config/environment';

// Encryption algorithm used
const ENCRYPTION_ALGORITHM = 'AES-GCM';
// Key derivation iterations
const PBKDF2_ITERATIONS = 100000;
// Salt size in bytes
const SALT_SIZE = 16;
// IV size in bytes
const IV_SIZE = 12;
// Length of authentication tag in bytes
const AUTH_TAG_LENGTH = 16;

export interface EncryptedMessage {
  iv: string;
  salt: string;
  encryptedData: string;
  authTag?: string;
}

export interface EncryptionMetadata {
  createdAt: string;
  expiresAt?: string;
  maxViews?: number;
  burnAfterReading: boolean;
  hasPassword: boolean;
  attachments: {
    id: string;
    name: string;
    type: string;
    size: number;
  }[];
  id: string;
}

export class EncryptionService {
  // Generate a cryptographically secure random key as bytes
  static generateKeyBytes(length = 32): Uint8Array {
    return crypto.getRandomValues(new Uint8Array(length));
  }

  // Convert bytes to hex string
  static bytesToHex(bytes: Uint8Array): string {
    return Array.from(bytes)
      .map(b => b.toString(16).padStart(2, '0'))
      .join('');
  }

  // Convert hex string to bytes
  static hexToBytes(hex: string): Uint8Array {
    if (hex.length % 2 !== 0) {
      throw new Error('Invalid hex string length');
    }
    const result = new Uint8Array(hex.length / 2);
    for (let i = 0; i < hex.length; i += 2) {
      result[i / 2] = parseInt(hex.substr(i, 2), 16);
    }
    return result;
  }

  // Generate a URL-friendly identifier
  static generateId(): string {
    return nanoid(10);
  }

  // Derive an encryption key from a password
  static async deriveKeyFromPassword(
    password: string, 
    salt: Uint8Array | null = null
  ): Promise<{ key: CryptoKey; salt: Uint8Array }> {
    // Generate salt if not provided
    if (!salt) {
      salt = crypto.getRandomValues(new Uint8Array(SALT_SIZE));
    }

    // Import the password as a key
    const passwordKey = await crypto.subtle.importKey(
      'raw',
      new TextEncoder().encode(password),
      { name: 'PBKDF2' },
      false,
      ['deriveBits', 'deriveKey']
    );

    // Derive a key using PBKDF2
    const derivedKey = await crypto.subtle.deriveKey(
      {
        name: 'PBKDF2',
        salt,
        iterations: PBKDF2_ITERATIONS,
        hash: 'SHA-256',
      },
      passwordKey,
      { name: ENCRYPTION_ALGORITHM, length: 256 },
      true,
      ['encrypt', 'decrypt']
    );

    return { key: derivedKey, salt };
  }

  // Encrypt message using modern Web Crypto API
  static async encryptMessage(
    message: string,
    password: string | null = null
  ): Promise<{ encrypted: EncryptedMessage; key: string }> {
    try {
      // Use provided password or generate a random key
      let key: CryptoKey;
      let salt: Uint8Array;
      let exportedKey: string;

      if (password) {
        const derived = await this.deriveKeyFromPassword(password);
        key = derived.key;
        salt = derived.salt;
        exportedKey = password;
      } else {
        // Generate a random key as bytes
        const rawKeyBytes = this.generateKeyBytes(32);
        key = await crypto.subtle.importKey(
          'raw',
          rawKeyBytes,
          { name: ENCRYPTION_ALGORITHM, length: 256 },
          false,
          ['encrypt', 'decrypt']
        );
        salt = crypto.getRandomValues(new Uint8Array(SALT_SIZE));
        // Export key as hex string for URL
        exportedKey = this.bytesToHex(rawKeyBytes);
      }

      // Generate a random IV
      const iv = crypto.getRandomValues(new Uint8Array(IV_SIZE));

      // Sanitize HTML content if needed
      const sanitizedMessage = this.sanitizeContent(message);
      const encodedMessage = new TextEncoder().encode(sanitizedMessage);

      // Encrypt the data
      const encryptedBuffer = await crypto.subtle.encrypt(
        {
          name: ENCRYPTION_ALGORITHM,
          iv,
          tagLength: AUTH_TAG_LENGTH * 8
        },
        key,
        encodedMessage
      );

      // Convert binary data to Base64 strings for storage
      return {
        encrypted: {
          iv: bufferToBase64(iv),
          salt: bufferToBase64(salt),
          encryptedData: bufferToBase64(new Uint8Array(encryptedBuffer))
        },
        key: exportedKey
      };
    } catch (error) {
      EnvironmentService.log('Encryption error:', error);
      throw new Error('Failed to encrypt message: ' + (error instanceof Error ? error.message : String(error)));
    }
  }

  // Decrypt message
  static async decryptMessage(
    encryptedMessage: EncryptedMessage,
    keyOrPassword: string
  ): Promise<string> {
    try {
      // Convert Base64 strings to binary data
      const iv = base64ToBuffer(encryptedMessage.iv);
      const salt = base64ToBuffer(encryptedMessage.salt);
      const encryptedData = base64ToBuffer(encryptedMessage.encryptedData);

      // Determine if using password or direct key
      // Passwords are typically shorter and contain non-hex characters
      const isPassword = keyOrPassword.length < 32 || !/^[0-9a-fA-F]+$/.test(keyOrPassword);
      let key: CryptoKey;

      if (isPassword) {
        // Derive key from password
        const derived = await this.deriveKeyFromPassword(keyOrPassword, salt);
        key = derived.key;
      } else {
        // Convert hex key to bytes and import
        const keyBytes = this.hexToBytes(keyOrPassword);
        key = await crypto.subtle.importKey(
          'raw',
          keyBytes,
          { name: ENCRYPTION_ALGORITHM, length: 256 },
          false,
          ['encrypt', 'decrypt']
        );
      }

      // Decrypt the data
      const decryptedBuffer = await crypto.subtle.decrypt(
        {
          name: ENCRYPTION_ALGORITHM,
          iv,
          tagLength: AUTH_TAG_LENGTH * 8
        },
        key,
        encryptedData
      );

      // Convert the decrypted data back to string
      return new TextDecoder().decode(decryptedBuffer);
    } catch (error) {
      EnvironmentService.log('Decryption error:', error);
      throw new Error('Failed to decrypt message. The key might be incorrect or the data is corrupted.');
    }
  }

  // Encrypt file
  static async encryptFile(
    file: File,
    password: string | null = null
  ): Promise<{ encryptedFile: Blob; key: string; metadata: any }> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = async (event) => {
        try {
          // Use provided password or generate a random key
          let key: CryptoKey;
          let salt: Uint8Array;
          let exportedKey: string;

          if (password) {
            const derived = await this.deriveKeyFromPassword(password);
            key = derived.key;
            salt = derived.salt;
            exportedKey = password;
          } else {
            // Generate a random key as bytes
            const rawKeyBytes = this.generateKeyBytes(32);
            key = await crypto.subtle.importKey(
              'raw',
              rawKeyBytes,
              { name: ENCRYPTION_ALGORITHM, length: 256 },
              false,
              ['encrypt', 'decrypt']
            );
            salt = crypto.getRandomValues(new Uint8Array(SALT_SIZE));
            exportedKey = this.bytesToHex(rawKeyBytes);
          }

          // Generate a random IV
          const iv = crypto.getRandomValues(new Uint8Array(IV_SIZE));

          // Convert file data to ArrayBuffer
          // @ts-ignore
          const fileData = new Uint8Array(event.target.result);

          // Encrypt the file
          const encryptedBuffer = await crypto.subtle.encrypt(
            {
              name: ENCRYPTION_ALGORITHM,
              iv,
              tagLength: AUTH_TAG_LENGTH * 8
            },
            key,
            fileData
          );

          // File metadata
          const metadata = {
            fileName: file.name,
            fileType: file.type,
            fileSize: file.size,
            iv: bufferToBase64(iv),
            salt: bufferToBase64(salt),
            encryptionAlgorithm: ENCRYPTION_ALGORITHM
          };

          // Bundle encrypted data and metadata
          const encryptedBlob = new Blob([encryptedBuffer], { type: 'application/octet-stream' });
          
          resolve({
            encryptedFile: encryptedBlob,
            key: exportedKey,
            metadata
          });
        } catch (error) {
          reject(error);
        }
      };
      
      reader.onerror = reject;
      reader.readAsArrayBuffer(file);
    });
  }
  
  // Decrypt file
  static async decryptFile(
    encryptedFile: Blob,
    metadata: any,
    keyOrPassword: string
  ): Promise<Blob> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = async (event) => {
        try {
          // Convert Base64 strings to binary data
          const iv = base64ToBuffer(metadata.iv);
          const salt = base64ToBuffer(metadata.salt);

          // Determine if using password or direct key
          const isPassword = keyOrPassword.length < 32 || !/^[0-9a-fA-F]+$/.test(keyOrPassword);
          let key: CryptoKey;

          if (isPassword) {
            // Derive key from password
            const derived = await this.deriveKeyFromPassword(keyOrPassword, salt);
            key = derived.key;
          } else {
            // Convert hex key to bytes and import
            const keyBytes = this.hexToBytes(keyOrPassword);
            key = await crypto.subtle.importKey(
              'raw',
              keyBytes,
              { name: ENCRYPTION_ALGORITHM, length: 256 },
              false,
              ['encrypt', 'decrypt']
            );
          }

          // @ts-ignore
          const encryptedData = new Uint8Array(event.target.result);

          // Decrypt the file
          const decryptedBuffer = await crypto.subtle.decrypt(
            {
              name: ENCRYPTION_ALGORITHM,
              iv,
              tagLength: AUTH_TAG_LENGTH * 8
            },
            key,
            encryptedData
          );
          
          // Create a blob with the original file type
          const decryptedBlob = new Blob([decryptedBuffer], { type: metadata.fileType });
          
          resolve(decryptedBlob);
        } catch (error) {
          reject(error);
        }
      };
      
      reader.onerror = reject;
      reader.readAsArrayBuffer(encryptedFile);
    });
  }

  // Download a decrypted file
  static downloadDecryptedFile(decryptedBlob: Blob, fileName: string): void {
    fileDownload(decryptedBlob, fileName);
  }

  // Create a shareable link with the encryption key in the URL fragment
  static createShareableLink(messageId: string, key: string): string {
    const baseUrl = EnvironmentService.getBaseUrl();
    return `${baseUrl}/message/${messageId}#${key}`;
  }

  // Extract message ID and key from a shareable link
  static parseShareableLink(link: string): { messageId: string; key: string } | null {
    try {
      const url = new URL(link);
      const pathSegments = url.pathname.split('/');
      const messageId = pathSegments[pathSegments.length - 1];
      const key = url.hash.substring(1); // Remove the # symbol
      
      if (messageId && key) {
        return { messageId, key };
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  // Sanitize HTML content to prevent XSS
  private static sanitizeContent(content: string): string {
    return sanitizeHtml(content, {
      allowedTags: [
        'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'blockquote', 'p', 'a', 'ul', 'ol',
        'nl', 'li', 'b', 'i', 'strong', 'em', 'strike', 'code', 'hr', 'br', 'div',
        'table', 'thead', 'caption', 'tbody', 'tr', 'th', 'td', 'pre', 'span'
      ],
      allowedAttributes: {
        a: ['href', 'target', 'rel'],
        span: ['style'],
        div: ['style'],
        '*': ['class']
      },
      allowedStyles: {
        '*': {
          // Allow limited styles for basic formatting
          'color': [/^#(0x)?[0-9a-f]+$/i, /^rgb\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*\)$/],
          'text-align': [/^left$/, /^right$/, /^center$/],
          'font-weight': [/^\d+$/],
          'text-decoration': [/^underline$/, /^line-through$/]
        }
      }
    });
  }

  // Evaluate password strength
  static evaluatePasswordStrength(password: string): {
    score: number;
    feedback: string;
  } {
    if (!password) {
      return { score: 0, feedback: 'Password is empty' };
    }

    // Very simple password evaluation logic
    // In a real implementation, use zxcvbn or a similar library
    let score = 0;
    const feedback = [];

    // Length check
    if (password.length < 8) {
      feedback.push('Password is too short');
    } else {
      score += 1;
    }

    // Complexity checks
    if (/[A-Z]/.test(password)) score += 1;
    if (/[a-z]/.test(password)) score += 1;
    if (/[0-9]/.test(password)) score += 1;
    if (/[^A-Za-z0-9]/.test(password)) score += 1;

    // Generate feedback based on score
    if (score < 2) {
      feedback.push('Password is very weak');
    } else if (score < 3) {
      feedback.push('Password is weak');
    } else if (score < 4) {
      feedback.push('Password is moderate');
    } else {
      feedback.push('Password is strong');
    }

    return {
      score: score,
      feedback: feedback.join('. ')
    };
  }
}
