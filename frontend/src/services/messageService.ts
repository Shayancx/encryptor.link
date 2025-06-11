// Service for handling encrypted messages

// Types for the API
export interface MessageCreationResponse {
  id: string;
  created_at: string;
  success: boolean;
}

export interface MessageRetrievalResponse {
  encrypted_data: string;
  metadata: {
    expires_at: string;
    max_views: number;
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
  success: boolean;
}

export interface ApiError {
  error: string;
  success: false;
}

// Create a new encrypted message
export const createMessage = async (
  encryptedData: string,
  metadata: {
    expiresAt?: string;
    maxViews?: number;
    burnAfterReading?: boolean;
    hasPassword?: boolean;
    files?: Array<{
      name: string;
      type: string;
      size: number;
      metadata: any;
    }>;
  }
): Promise<MessageCreationResponse | ApiError> => {
  try {
    // Format the request to match backend expectations
    const requestBody = {
      data: {
        encrypted_data: encryptedData,
        metadata: {
          expires_at: metadata.expiresAt,
          max_views: metadata.maxViews,
          burn_after_reading: metadata.burnAfterReading,
          has_password: metadata.hasPassword,
          files: metadata.files?.map(file => ({
            name: file.name,
            type: file.type,
            size: file.size,
            metadata: file.metadata
          }))
        }
      }
    };

    console.log('Sending request to create message:', JSON.stringify(requestBody));

    const response = await fetch('/api/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(requestBody)
    });

    const data = await response.json();
    
    if (!response.ok) {
      console.error('Error creating message:', data);
      return { error: data.error || 'Unknown error', success: false };
    }

    return data as MessageCreationResponse;
  } catch (error) {
    console.error('Error in message service:', error);
    return { 
      error: error instanceof Error ? error.message : 'Unknown error',
      success: false
    };
  }
};

// Retrieve a message by ID
export const getMessage = async (
  id: string
): Promise<MessageRetrievalResponse | ApiError> => {
  try {
    const response = await fetch(`/api/v1/messages/${id}`);
    const data = await response.json();
    
    if (!response.ok) {
      console.error('Error retrieving message:', data);
      return { error: data.error || 'Unknown error', success: false };
    }

    return data as MessageRetrievalResponse;
  } catch (error) {
    console.error('Error in message service:', error);
    return { 
      error: error instanceof Error ? error.message : 'Unknown error', 
      success: false
    };
  }
};
