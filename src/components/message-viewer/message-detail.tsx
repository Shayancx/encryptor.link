import React, { useState, useEffect } from 'react';
import { useParams, useLocation } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent } from '@/components/ui/card';
import { Lock, AlertTriangle, Eye, Clock } from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';
import { ApiService } from '@/services/api-service';
import { EncryptionService } from '@/services/encryption-service';
import { EnvironmentService } from '@/config/environment';
import { getTimeRemaining } from '@/services/utils';

export function MessageDetail() {
  const { id } = useParams<{ id: string }>();
  const location = useLocation();
  const [password, setPassword] = useState('');
  const [needsPassword, setNeedsPassword] = useState(false);
  const [message, setMessage] = useState<any>(null);
  const [decryptedContent, setDecryptedContent] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [timeRemaining, setTimeRemaining] = useState<any>(null);
  const { toast } = useToast();

  // Extract key from URL fragment
  const getKeyFromFragment = () => {
    return location.hash.substring(1);
  };

  // Fetch message data
  const fetchMessage = async () => {
    if (!id) {
      setError('No message ID provided');
      setIsLoading(false);
      return;
    }

    try {
      setIsLoading(true);
      const data = await ApiService.getMessage(id);

      if (data.deleted) {
        setError('This message has been deleted or has expired');
        setIsLoading(false);
        return;
      }

      setMessage(data);

      // Try to decrypt with key from URL fragment
      const key = getKeyFromFragment();
      if (key) {
        await decryptMessageContent(data.encrypted_data, key);
      } else {
        setError('No decryption key provided');
      }

      // Track view if successfully loaded
      await ApiService.viewMessage(id);
    } catch (error) {
      console.error('Error fetching message:', error);
      setError('Failed to load the encrypted message');
    } finally {
      setIsLoading(false);
    }
  };

  // Decrypt message content
  const decryptMessageContent = async (encryptedData: string, key: string) => {
    try {
      // Parse encrypted data
      const parsedData = JSON.parse(encryptedData);
      
      // Determine if password is needed
      if (message?.metadata?.has_password && !password) {
        setNeedsPassword(true);
        return;
      }

      // Decrypt the content
      const keyToUse = message?.metadata?.has_password ? password : key;
      const decrypted = await EncryptionService.decryptMessage(parsedData, keyToUse);
      setDecryptedContent(decrypted);
      setNeedsPassword(false);
    } catch (error) {
      console.error('Decryption error:', error);
      
      if (message?.metadata?.has_password) {
        setNeedsPassword(true);
        setError('Invalid password. Please try again.');
      } else {
        setError('Failed to decrypt message. The key might be incorrect or the data is corrupted.');
      }
    }
  };

  // Handle password submission
  const handleSubmitPassword = async () => {
    if (!password) {
      toast({
        title: "Error",
        description: "Please enter a password",
        variant: "destructive",
      });
      return;
    }

    setError(null);
    await decryptMessageContent(message.encrypted_data, password);
  };

  // Update time remaining countdown
  useEffect(() => {
    if (!message?.expires_at) return;
    
    const expiresAt = new Date(message.expires_at);
    
    const updateTimeRemaining = () => {
      const remaining = getTimeRemaining(expiresAt);
      if (remaining.days <= 0 && remaining.hours <= 0 && 
          remaining.minutes <= 0 && remaining.seconds <= 0) {
        setError('This message has expired');
        setTimeRemaining(null);
        clearInterval(interval);
      } else {
        setTimeRemaining(remaining);
      }
    };
    
    updateTimeRemaining();
    const interval = setInterval(updateTimeRemaining, 1000);
    
    return () => clearInterval(interval);
  }, [message?.expires_at]);

  // Fetch message on component mount
  useEffect(() => {
    fetchMessage();
  }, [id]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <div className="animate-spin h-8 w-8 border-4 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
          <p>Loading encrypted message...</p>
        </div>
      </div>
    );
  }

  if (error && !needsPassword) {
    return (
      <Card className="border-destructive">
        <CardContent className="pt-6">
          <div className="flex flex-col items-center text-center gap-4">
            <AlertTriangle className="h-12 w-12 text-destructive" />
            <div>
              <h2 className="text-xl font-bold mb-2">Error</h2>
              <p>{error}</p>
            </div>
            <Button onClick={() => window.location.href = '/'}>
              Back to Home
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (needsPassword) {
    return (
      <Card>
        <CardContent className="pt-6">
          <div className="flex flex-col items-center text-center gap-4">
            <Lock className="h-12 w-12 text-primary" />
            <div>
              <h2 className="text-xl font-bold mb-2">Password Protected</h2>
              <p>This message is protected with a password.</p>
            </div>
            
            <div className="w-full max-w-xs space-y-4">
              <Input
                type="password"
                placeholder="Enter password to decrypt"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
              
              {error && <p className="text-destructive text-sm">{error}</p>}
              
              <Button onClick={handleSubmitPassword} className="w-full">
                Decrypt Message
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h2 className="text-2xl font-bold tracking-tight">Decrypted Message</h2>
      </div>
      
      <Card>
        <CardContent className="pt-6 space-y-4">
          {timeRemaining && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground mb-4">
              <Clock className="h-4 w-4" />
              <span>
                Expires in: {timeRemaining.days > 0 ? `${timeRemaining.days}d ` : ''}
                {String(timeRemaining.hours).padStart(2, '0')}:
                {String(timeRemaining.minutes).padStart(2, '0')}:
                {String(timeRemaining.seconds).padStart(2, '0')}
              </span>
            </div>
          )}

          {message?.remaining_views !== null && (
            <div className="flex items-center gap-2 text-sm text-muted-foreground mb-4">
              <Eye className="h-4 w-4" />
              <span>
                {message.remaining_views === 1 
                  ? 'This is your last view'
                  : `${message.remaining_views} views remaining`}
              </span>
            </div>
          )}

          <div className="border rounded-md p-4 prose prose-sm dark:prose-invert max-w-none">
            <div dangerouslySetInnerHTML={{ __html: decryptedContent || '' }} />
          </div>
          
          <div className="flex justify-end">
            <Button onClick={() => window.location.href = '/'}>
              Back to Home
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
