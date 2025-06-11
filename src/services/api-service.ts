import { EnvironmentService } from '@/config/environment';

export interface MessageRequest {
  data: {
    encrypted_data: string;
    metadata: {
      expires_at?: string;
      max_views?: number;
      burn_after_reading: boolean;
      has_password: boolean;
      files: any[];
    };
    files?: any[];
  };
}

export interface MessageResponse {
  id: string;
  encrypted_data: string;
  metadata: any;
  created_at: string;
  expires_at?: string;
  remaining_views?: number;
  deleted: boolean;
}

export interface FileResponse {
  data: string;
  metadata: any;
}

export interface ErrorResponse {
  error: string;
  status: number;
}

export class ApiService {
  // Use relative URLs in development to leverage Vite proxy, absolute URLs in production
  private static getBaseUrl(): string {
    if (EnvironmentService.isDevelopment()) {
      // Use relative URLs so they go through Vite proxy
      return '/api/v1';
    } else {
      // Use absolute URLs in production
      return EnvironmentService.getApiUrl();
    }
  }
  
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
    const baseUrl = this.getBaseUrl();
    const url = new URL(`${baseUrl}${endpoint}`, window.location.origin);
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
      const baseUrl = this.getBaseUrl();
      const url = new URL(`${baseUrl}${endpoint}`, window.location.origin);
      
      if (EnvironmentService.isDevelopment()) {
        console.log(`POST request to: ${url.toString()}`, data);
      }
      
      const response = await fetch(url.toString(), {
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
    // Handle files separately if present
    if (data.data.files && data.data.files.length > 0) {
      // First create the message
      const messageData = {
        ...data,
        data: {
          ...data.data,
          files: undefined // Remove files from initial message creation
        }
      };
      
      const messageResponse = await this.post<MessageResponse>('/messages', messageData);
      
      // Then upload files
      for (const file of data.data.files) {
        await this.uploadFile(messageResponse.id, file);
      }
      
      return messageResponse;
    }
    
    return this.post<MessageResponse>('/messages', data);
  }

  /**
   * Upload an encrypted file
   */
  static async uploadFile(messageId: string, fileData: any): Promise<any> {
    return this.post<any>(`/messages/${messageId}/files`, {
      data: fileData.data,
      name: fileData.name,
      type: fileData.type,
      size: fileData.size,
      metadata: fileData.metadata
    });
  }

  /**
   * Get file data
   */
  static async getFile(messageId: string, fileName: string): Promise<FileResponse> {
    return this.get<FileResponse>(`/messages/${messageId}/files/${encodeURIComponent(fileName)}`);
  }

  /**
   * Retrieve an encrypted message
   */
  static async getMessage(id: string): Promise<MessageResponse> {
    return this.get<MessageResponse>(`/messages/${id}`);
  }

  /**
   * Mark a message as viewed
   */
  static async viewMessage(id: string): Promise<any> {
    return this.post<any>(`/messages/${id}/view`, {});
  }

  /**
   * Health check to test API connectivity
   */
  static async healthCheck(): Promise<any> {
    return this.get<any>('/health');
  }
}
