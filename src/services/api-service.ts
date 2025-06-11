import { EnvironmentService } from '@/config/environment';

export interface MessageRequest {
  data: {
    encrypted_data: string;
    metadata: {
      expires_at?: string;
      max_views?: number;
      burn_after_reading: boolean;
      has_password: boolean;
      attachments: any[];
    };
  };
}

export interface MessageResponse {
  id: string;
  created_at: string;
  expires_at?: string;
  remaining_views?: number;
  deleted: boolean;
}

export interface ErrorResponse {
  error: string;
  status: number;
}

export class ApiService {
  // Base API URL from environment
  private static baseUrl = EnvironmentService.getApiUrl();
  
  // Default headers for API requests
  private static defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /**
   * Handle API response
   */
  private static async handleResponse<T>(response: Response): Promise<T> {
    const contentType = response.headers.get('content-type');
    let data: any;
    
    try {
      // Parse response body based on content type
      if (contentType && contentType.includes('application/json')) {
        data = await response.json();
      } else {
        data = await response.text();
      }
      
      // Handle error responses
      if (!response.ok) {
        // Log the error response in development
        if (EnvironmentService.isDevelopment()) {
          console.error('API Error:', response.status, data);
        }
        
        const error: ErrorResponse = {
          error: typeof data === 'object' && data.error ? data.error : 'Request failed with status: ' + response.status,
          status: response.status
        };
        
        throw error;
      }
      
      return data as T;
    } catch (error) {
      if (EnvironmentService.isDevelopment()) {
        console.error('Response handling error:', error);
      }
      
      if (error instanceof SyntaxError) {
        // Handle JSON parsing error
        throw { error: 'Invalid response format', status: response.status };
      }
      
      throw error;
    }
  }

  /**
   * Make a GET request
   */
  static async get<T>(endpoint: string, params: Record<string, string> = {}): Promise<T> {
    // Build URL with query parameters
    const url = new URL(`${this.baseUrl}${endpoint}`);
    Object.keys(params).forEach(key => {
      url.searchParams.append(key, params[key]);
    });

    try {
      if (EnvironmentService.isDevelopment()) {
        console.log(`GET request to: ${url.toString()}`);
      }
      
      const response = await fetch(url.toString(), {
        method: 'GET',
        headers: this.defaultHeaders,
        credentials: 'include',
      });

      return this.handleResponse<T>(response);
    } catch (error) {
      if (EnvironmentService.isDevelopment()) {
        console.error('GET request failed:', error);
      }
      throw { error: 'Network error', status: 0 };
    }
  }

  /**
   * Make a POST request
   */
  static async post<T>(endpoint: string, data: any): Promise<T> {
    try {
      if (EnvironmentService.isDevelopment()) {
        console.log(`POST request to: ${this.baseUrl}${endpoint}`, data);
      }
      
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        method: 'POST',
        headers: this.defaultHeaders,
        body: JSON.stringify(data),
        credentials: 'include',
      });

      return this.handleResponse<T>(response);
    } catch (error) {
      if (EnvironmentService.isDevelopment()) {
        console.error('POST request failed:', error);
      }
      throw { error: 'Network error', status: 0 };
    }
  }

  /**
   * Create a new encrypted message
   */
  static async createMessage(data: MessageRequest): Promise<MessageResponse> {
    return this.post<MessageResponse>('/messages', data);
  }

  /**
   * Retrieve an encrypted message
   */
  static async getMessage(id: string): Promise<any> {
    return this.get<any>(`/messages/${id}`);
  }

  /**
   * Mark a message as viewed
   */
  static async viewMessage(id: string): Promise<any> {
    return this.post<any>(`/messages/${id}/view`, {});
  }

  /**
   * Upload an encrypted file
   */
  static async uploadFile(file: File, messageId: string): Promise<any> {
    try {
      const formData = new FormData();
      formData.append('file', file);
      formData.append('message_id', messageId);

      if (EnvironmentService.isDevelopment()) {
        console.log(`Uploading file to: ${this.baseUrl}/files`, { fileName: file.name, size: file.size });
      }

      const response = await fetch(`${this.baseUrl}/files`, {
        method: 'POST',
        body: formData,
        credentials: 'include',
      });

      return this.handleResponse(response);
    } catch (error) {
      if (EnvironmentService.isDevelopment()) {
        console.error('File upload failed:', error);
      }
      throw { error: 'Network error', status: 0 };
    }
  }

  /**
   * Download an encrypted file
   */
  static async downloadFile(fileId: string): Promise<Blob> {
    try {
      if (EnvironmentService.isDevelopment()) {
        console.log(`Downloading file: ${this.baseUrl}/files/${fileId}`);
      }
      
      const response = await fetch(`${this.baseUrl}/files/${fileId}`, {
        method: 'GET',
        credentials: 'include',
      });

      if (!response.ok) {
        throw { error: 'Failed to download file', status: response.status };
      }

      return await response.blob();
    } catch (error) {
      if (EnvironmentService.isDevelopment()) {
        console.error('File download failed:', error);
      }
      throw { error: 'Network error', status: 0 };
    }
  }

  /**
   * Health check to test API connectivity
   */
  static async healthCheck(): Promise<any> {
    return this.get<any>('/health');
  }
}
