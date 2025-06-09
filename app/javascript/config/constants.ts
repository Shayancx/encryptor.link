export interface AppConfig {
  MAX_FILE_SIZE: number;
  MAX_TTL_DAYS: number;
  ENCRYPTION_ALGORITHM: string;
}

export const CONFIG: AppConfig = {
  MAX_FILE_SIZE: 1000 * 1024 * 1024, // 1000MB
  MAX_TTL_DAYS: 7,
  ENCRYPTION_ALGORITHM: 'AES-GCM'
};

export default CONFIG;
