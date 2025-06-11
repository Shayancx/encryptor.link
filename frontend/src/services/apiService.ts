// API endpoints
const API_URL = '/api/v1';

// Interface for API responses
interface ApiResponse<T> {
  data?: T;
  error?: string;
}

// Interface for message creation response
interface MessageCreationResponse {
  id: string;
  file_ids: string[];
}

// Interface for message retrieval response
interface MessageResponse {
  payload: string;
  files: {
    id: string;
    content_type: string;
    size: number;
  }[];
}

// Interface for file upload data
interface FileUploadData {
  file_id: string;
  encrypted_file: string;
  content_type: string;
  size: number;
}

// Create a new encrypted message with optional files
export const createMessage = async (
  payload: string = '',
  files: FileUploadData[] = []
): Promise<ApiResponse<MessageCreationResponse>> => {
  try {
    const response = await fetch(`${API_URL}/messages`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        payload,
        files
      }),
    });
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || `HTTP error! Status: ${response.status}`);
    }
    
    const data = await response.json();
    return { data };
  } catch (error) {
    console.error('API error creating message:', error);
    return { error: error instanceof Error ? error.message : 'Unknown error occurred' };
  }
};

// Retrieve an encrypted message by its ID
export const getMessage = async (
  messageId: string
): Promise<ApiResponse<MessageResponse>> => {
  try {
    const response = await fetch(`${API_URL}/messages/${messageId}`);
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || `HTTP error! Status: ${response.status}`);
    }
    
    const data = await response.json();
    return { data };
  } catch (error) {
    console.error('API error retrieving message:', error);
    return { error: error instanceof Error ? error.message : 'Unknown error occurred' };
  }
};

// Get a file from an encrypted message
export const getFile = async (
  messageId: string,
  fileId: string
): Promise<ApiResponse<Blob>> => {
  try {
    const response = await fetch(`${API_URL}/messages/${messageId}/files/${fileId}`);
    
    if (!response.ok) {
      const errorData = await response.json();
      throw new Error(errorData.error || `HTTP error! Status: ${response.status}`);
    }
    
    const blob = await response.blob();
    return { data: blob };
  } catch (error) {
    console.error('API error retrieving file:', error);
    return { error: error instanceof Error ? error.message : 'Unknown error occurred' };
  }
};
