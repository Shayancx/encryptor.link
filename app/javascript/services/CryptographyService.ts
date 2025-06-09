import { encryptMessage, encryptFiles } from '../lib/encrypt';
import { EncryptionOptions, ProgressCallback, CancelToken } from '../types/crypto.types';

export class CryptographyService {
  static async encryptMessage(
    message: string,
    ttl: number,
    views: number,
    password: string = '',
    burnAfterReading: boolean = false
  ): Promise<string> {
    try {
      return await encryptMessage(message, ttl, views, password, burnAfterReading);
    } catch (error) {
      console.error('Encryption failed:', error);
      throw new Error(`Encryption failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  static async encryptFiles(
    files: File[],
    message: string,
    ttl: number,
    views: number,
    password: string = '',
    burnAfterReading: boolean = false,
    progressCallback?: ProgressCallback,
    cancelToken?: CancelToken
  ): Promise<string> {
    try {
      return await encryptFiles(
        files,
        message,
        ttl,
        views,
        password,
        burnAfterReading,
        progressCallback,
        cancelToken
      );
    } catch (error) {
      console.error('File encryption failed:', error);
      throw new Error(`File encryption failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }
}

export default CryptographyService;
