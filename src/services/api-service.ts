import { EnvironmentService } from '@/config/environment';

export interface MessageRequest {
  data: {
    encrypted_data: string;
    metadata: {
      expires_at?: string;
      max_views?: number;
      burn_after_reading: boolean;
      has_password: boolean;
      files: Array<{
        name: string;
        type: string;
        size: number;
        metadata: any;
      }>;
    };
    files?: Array<{
      name: string;
      type: string;
      size: number;
      data: string;
      metadata: any;
    }>;
  };
}

export interface MessageResponse {
  id: string;
  created_at: string;
  success: boolean;
}

export interface MessageData {
  encrypted_data: string;
  metadata: {
    expires_at: string;
    max_views: number;
    remaining_views: number;
    burn_after_reading: boolean;
    has_password: boolean;
    files: Array<{
      id: string;
      name: string;
      type: string;
      size: number;
      metadata: any;
    }>;
  };
  deleted: boolean;
  success: boolean;
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
  private static getBaseUrl(): string {
    // Always use relative URLs in production
    return '/api/v1';
  }
  
  private static defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  private static async handleResponse<T>(response: Response): Promise<T> {
    const contentType = response.headers.get('content-type');
    let data: any;
    
    try {
      if (contentType && contentType.includes('application/json')) {
        data = await response.json();
      } else {
        const text = await response.text();
        // Try to parse as JSON anyway
        try {
          data = JSON.parse(text);
        } catch {
          data = { error: text || 'Unknown error' };
        }
      }
      
      if (!response.ok) {
        if (EnvironmentService.isDevelopment()) {
          console.error('API Error:', response.status, data);
        }
        
        const error: ErrorResponse = {
          error: (typeof data === 'object' && data.error) ? data.error : 'Request failed',
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
        throw { error: 'Invalid response format', status: response.status };
      }
      
      throw error;
    }
  }

  static async get<T>(endpoint: string): Promise<T> {
    const baseUrl = this.getBaseUrl();
    const url = `${baseUrl}${endpoint}`;

    try {
      if (EnvironmentService.isDevelopment()) {
        console.log(`GET request to: ${url}`);
      }
      
      const response = await fetch(url, {
        method: 'GET',
        headers: this.defaultHeaders,
        credentials: 'same-origin',
      });

      return this.handleResponse<T>(response);
    } catch (error) {
      if (EnvironmentService.isDevelopment()) {
        console.error('GET request failed:', error);
      }
      throw error;
    }
  }

  static async post<T>(endpoint: string, data: any): Promise<T> {
    try {
      const baseUrl = this.getBaseUrl();
      const url = `${baseUrl}${endpoint}`;
      
      if (EnvironmentService.isDevelopment()) {
        console.log(`POST request to: ${url}`, data);
      }
      
      const response = await fetch(url, {
        method: 'POST',
        headers: this.defaultHeaders,
        body: JSON.stringify(data),
        credentials: 'same-origin',
      });

      return this.handleResponse<T>(response);
    } catch (error) {
      if (EnvironmentService.isDevelopment()) {
        console.error('POST request failed:', error);
      }
      throw error;
    }
  }

  static async createMessage(data: MessageRequest): Promise<MessageResponse> {
    return this.post<MessageResponse>('/messages', data);
  }

  static async getMessage(id: string): Promise<MessageData> {
    return this.get<MessageData>(`/messages/${id}`);
  }

  static async viewMessage(id: string): Promise<any> {
    return this.post<any>(`/messages/${id}/view`, {});
  }

  static async getFile(messageId: string, fileName: string): Promise<FileResponse> {
    // Double encode to handle special characters properly
    const encodedFileName = encodeURIComponent(encodeURIComponent(fileName));
    return this.get<FileResponse>(`/messages/${messageId}/files/${encodedFileName}`);
  }

  static async healthCheck(): Promise<any> {
    return this.get<any>('/health');
  }
}
