interface Window {
  CSRFHelper: typeof CSRFHelper;
  fs?: {
    readFile: (path: string, options?: { encoding?: string }) => Promise<ArrayBuffer | string>;
  };
  Stimulus?: any;
}

declare module '*.scss' {
  const content: { [className: string]: string };
  export default content;
}

declare class CSRFHelper {
  static getToken(): string | null;
  static getHeaders(additionalHeaders?: Record<string, string>): Record<string, string>;
  static fetchWithCSRF(url: string, options?: RequestInit): Promise<Response>;
}
