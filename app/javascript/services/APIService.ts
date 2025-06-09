/// <reference path="../types/global.d.ts" />

interface APIResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
}

export class APIService {
  private static abortControllers: Map<string, AbortController> = new Map();

  static async postEncrypt(payload: any): Promise<Response> {
    return this.makeRequest('encrypt', () => 
      CSRFHelper.fetchWithCSRF('/encrypt', {
        method: 'POST',
        body: JSON.stringify(payload)
      })
    );
  }

  static async getPayloadData(id: string): Promise<Response> {
    const cacheBuster = Date.now();
    return this.makeRequest(`payload-${id}`, () =>
      fetch(`/${id}/data?t=${cacheBuster}`, {
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      })
    );
  }

  static async getPayloadInfo(id: string): Promise<Response> {
    return this.makeRequest(`info-${id}`, () =>
      fetch(`/${id}/info`, {
        headers: { 'Accept': 'application/json' }
      })
    );
  }

  private static async makeRequest(
    key: string,
    requestFn: () => Promise<Response>
  ): Promise<Response> {
    // Cancel any existing request with the same key
    this.cancelRequest(key);

    // Create new abort controller
    const controller = new AbortController();
    this.abortControllers.set(key, controller);

    try {
      const response = await requestFn();
      this.abortControllers.delete(key);
      return response;
    } catch (error) {
      this.abortControllers.delete(key);
      throw error;
    }
  }

  static cancelRequest(key: string): void {
    const controller = this.abortControllers.get(key);
    if (controller) {
      controller.abort();
      this.abortControllers.delete(key);
    }
  }

  static cancelAllRequests(): void {
    this.abortControllers.forEach(controller => controller.abort());
    this.abortControllers.clear();
  }
}

export default APIService;
