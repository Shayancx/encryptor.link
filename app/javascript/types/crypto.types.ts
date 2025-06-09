export interface EncryptionKey {
  key: CryptoKey;
  salt?: Uint8Array;
}

export interface EncryptedPayload {
  id: string;
  ciphertext: string;
  nonce: string;
  passwordProtected: boolean;
  passwordSalt?: string;
  files?: EncryptedFile[];
  burnAfterReading?: boolean;
  destructionCertificateId?: string;
}

export interface EncryptedFile {
  id: string;
  data: string;
  name: string;
  type: string;
  size: number;
}

export interface EncryptionOptions {
  ttl: number;
  views: number;
  password?: string;
  burnAfterReading?: boolean;
}

export interface DecryptionResult {
  success: boolean;
  data?: string;
  error?: string;
}

export type ProgressCallback = (progress: {
  percentage: number;
  status: string;
  details?: string;
  speed?: number;
  eta?: number;
}) => void;

export interface CancelToken {
  canceled: boolean;
  cancel(): void;
}
