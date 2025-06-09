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
