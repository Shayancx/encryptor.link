import { useEffect, useState } from 'react';
import { ApiService } from '@/services/api-service';
import { Button } from '@/components/ui/button';

export function ApiTest() {
  const [apiStatus, setApiStatus] = useState<string>('Not tested');
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const testApi = async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      const response = await ApiService.fetchMessages();
      setApiStatus(`API connected! Response: ${response.message}`);
    } catch (err) {
      setError('Failed to connect to API. Make sure both frontend and backend are running.');
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="p-4 border rounded-md space-y-4">
      <h2 className="text-lg font-medium">API Connection Test</h2>
      
      <div className="space-y-2">
        <p>Status: {isLoading ? 'Testing...' : apiStatus}</p>
        {error && <p className="text-red-500">{error}</p>}
      </div>
      
      <Button onClick={testApi} disabled={isLoading}>
        {isLoading ? 'Testing...' : 'Test API Connection'}
      </Button>
    </div>
  );
}
