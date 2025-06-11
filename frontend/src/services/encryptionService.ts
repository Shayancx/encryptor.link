import { v4 as uuidv4 } from 'uuid';
import CryptoJS from 'crypto-js';

// Generate a random encryption key
export const generateEncryptionKey = (): string => {
  return CryptoJS.lib.WordArray.random(32).toString();
};

// Encrypt message with the given key
export const encryptMessage = (message: string, key: string): string => {
  if (!message) return '';
  return CryptoJS.AES.encrypt(message, key).toString();
};

// Decrypt message with the given key
export const decryptMessage = (encryptedMessage: string, key: string): string => {
  if (!encryptedMessage) return '';
  try {
    const bytes = CryptoJS.AES.decrypt(encryptedMessage, key);
    return bytes.toString(CryptoJS.enc.Utf8);
  } catch (error) {
    console.error('Failed to decrypt message:', error);
    return '';
  }
};

// Encrypt a file
export const encryptFile = async (file: File, key: string): Promise<{
  file_id: string;
  encrypted_file: string;
  content_type: string;
  size: number;
}> => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    
    reader.onload = (event) => {
      try {
        if (!event.target?.result) {
          throw new Error('Failed to read file');
        }
        
        const arrayBuffer = event.target.result as ArrayBuffer;
        const wordArray = CryptoJS.lib.WordArray.create(arrayBuffer as any);
        const encryptedData = CryptoJS.AES.encrypt(wordArray, key).toString();
        
        resolve({
          file_id: uuidv4(),
          encrypted_file: encryptedData,
          content_type: file.type || 'application/octet-stream',
          size: file.size
        });
      } catch (error) {
        reject(error);
      }
    };
    
    reader.onerror = () => {
      reject(new Error('Failed to read file'));
    };
    
    reader.readAsArrayBuffer(file);
  });
};

// Decrypt a file
export const decryptFile = async (
  encryptedData: string, 
  contentType: string, 
  key: string
): Promise<Blob> => {
  try {
    const decrypted = CryptoJS.AES.decrypt(encryptedData, key);
    const typedArray = convertWordArrayToUint8Array(decrypted);
    return new Blob([typedArray], { type: contentType });
  } catch (error) {
    console.error('Failed to decrypt file:', error);
    throw error;
  }
};

// Helper to convert WordArray to Uint8Array
function convertWordArrayToUint8Array(wordArray: any): Uint8Array {
  const arrayOfWords = wordArray.hasOwnProperty('words') ? wordArray.words : [];
  const length = wordArray.hasOwnProperty('sigBytes') ? wordArray.sigBytes : arrayOfWords.length * 4;
  const uint8Array = new Uint8Array(length);
  let index = 0, word, i;
  
  for (i = 0; i < length; i += 4) {
    word = arrayOfWords[i / 4];
    if (word) {
      uint8Array[index++] = (word >> 24) & 0xff;
      if (index < length) uint8Array[index++] = (word >> 16) & 0xff;
      if (index < length) uint8Array[index++] = (word >> 8) & 0xff;
      if (index < length) uint8Array[index++] = word & 0xff;
    }
  }
  
  return uint8Array;
}
