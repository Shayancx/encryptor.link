import CryptoJS from 'crypto-js';
import fileDownload from 'js-file-download';

export interface EncryptedMessage {
  iv: string;
  encryptedData: string;
}

export class EncryptionService {
  // Generate a random encryption key
  static generateKey(): string {
    return CryptoJS.lib.WordArray.random(16).toString();
  }

  // Encrypt message
  static encryptMessage(message: string, key: string): EncryptedMessage {
    // Generate a random IV
    const iv = CryptoJS.lib.WordArray.random(16);
    
    // Encrypt the message
    const encrypted = CryptoJS.AES.encrypt(message, key, {
      iv: iv,
      padding: CryptoJS.pad.Pkcs7,
      mode: CryptoJS.mode.CBC
    });

    return {
      iv: iv.toString(),
      encryptedData: encrypted.toString()
    };
  }

  // Decrypt message
  static decryptMessage(encryptedMessage: EncryptedMessage, key: string): string {
    // Decrypt
    const decrypted = CryptoJS.AES.decrypt(encryptedMessage.encryptedData, key, {
      iv: CryptoJS.enc.Hex.parse(encryptedMessage.iv),
      padding: CryptoJS.pad.Pkcs7,
      mode: CryptoJS.mode.CBC
    });
    
    return decrypted.toString(CryptoJS.enc.Utf8);
  }

  // Encrypt file
  static encryptFile(file: File): Promise<{ encryptedFile: Blob; key: string }> {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (event) => {
        try {
          const key = this.generateKey();
          const iv = CryptoJS.lib.WordArray.random(16);
          
          // Convert file data to WordArray
          const wordArray = CryptoJS.lib.WordArray.create(
            // @ts-ignore
            new Uint8Array(event.target.result)
          );
          
          // Encrypt the file
          const encrypted = CryptoJS.AES.encrypt(wordArray, key, {
            iv: iv,
            padding: CryptoJS.pad.Pkcs7,
            mode: CryptoJS.mode.CBC
          }).toString();
          
          // Bundle IV and encrypted data
          const encryptedBundle = JSON.stringify({
            iv: iv.toString(),
            encryptedData: encrypted,
            fileName: file.name,
            fileType: file.type
          });
          
          // Convert to Blob
          const encryptedBlob = new Blob([encryptedBundle], { type: 'application/json' });
          
          resolve({
            encryptedFile: encryptedBlob,
            key
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
  static decryptFile(encryptedFileData: any, key: string): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        const { iv, encryptedData, fileName, fileType } = encryptedFileData;
        
        // Decrypt the file
        const decrypted = CryptoJS.AES.decrypt(encryptedData, key, {
          iv: CryptoJS.enc.Hex.parse(iv),
          padding: CryptoJS.pad.Pkcs7,
          mode: CryptoJS.mode.CBC
        });
        
        // Convert WordArray to ArrayBuffer
        const typedArray = this.convertWordArrayToUint8Array(decrypted);
        const blob = new Blob([typedArray], { type: fileType });
        
        // Download the file
        fileDownload(blob, fileName);
        resolve();
      } catch (error) {
        reject(error);
      }
    });
  }
  
  // Helper function to convert WordArray to TypedArray
  private static convertWordArrayToUint8Array(wordArray: any): Uint8Array {
    const words = wordArray.words;
    const sigBytes = wordArray.sigBytes;
    const u8 = new Uint8Array(sigBytes);
    
    for (let i = 0; i < sigBytes; i++) {
      const byte = (words[i >>> 2] >>> (24 - (i % 4) * 8)) & 0xff;
      u8[i] = byte;
    }
    
    return u8;
  }
}
