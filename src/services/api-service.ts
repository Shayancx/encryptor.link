// Basic API service for communicating with backend
export class ApiService {
  static async fetchMessages() {
    try {
      const response = await fetch('/api/v1/messages');
      if (!response.ok) throw new Error('Network response was not ok');
      return await response.json();
    } catch (error) {
      console.error('Error fetching messages:', error);
      throw error;
    }
  }

  static async createMessage(messageData: any) {
    try {
      const response = await fetch('/api/v1/messages', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(messageData),
      });
      
      if (!response.ok) throw new Error('Network response was not ok');
      return await response.json();
    } catch (error) {
      console.error('Error creating message:', error);
      throw error;
    }
  }
}
