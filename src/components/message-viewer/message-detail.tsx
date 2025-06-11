import React, { useState, useEffect } from 'react';
import { useParams, useLocation } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent } from '@/components/ui/card';
import { Lock, AlertTriangle, Eye, Clock, CheckCircle } from 'lucide-react';
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
  const [showOneTimeWarning, setShowOneTimeWarning] = useState(false);
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
      if (EnvironmentService.isDevelopment()) {
        console.log('Fetching message with ID:', id);
      }
      
      const data = await ApiService.getMessage(id);

      if (EnvironmentService.isDevelopment()) {
        console.log('Fetched message data:', data);
      }

      if (data.deleted) {
        setError('This message has been deleted or has expired');
        setIsLoading(false);
        return;
      }

      setMessage(data);

      // Show one-time warning if applicable
      if (data.remaining_views === 1 || data.metadata?.burn_after_reading) {
        setShowOneTimeWarning(true);
      }

      // Try to decrypt with key from URL fragment
      const key = getKeyFromFragment();
      if (key) {
        await decryptMessageContent(data.encrypted_data, key, data.metadata);
      } else {
        setError('No decryption key provided in URL');
      }

      // Track view if successfully loaded and decrypted
      if (decryptedContent) {
        try {
          await ApiService.viewMessage(id);
          if (EnvironmentService.isDevelopment()) {
            console.log('View tracked successfully');
          }
        } catch (viewError) {
          console.warn('Failed to track view:', viewError);
        }
      }
    } catch (error: any) {
      console.error('Error fetching message:', error);
      
      if (error.status === 404) {
        setError('This message does not exist or has been deleted');
      } else if (error.status === 410) {
        setError('This message has expired or reached its view limit');
      } else {
        setError('Failed to load the encrypted message: ' + (error.error || error.message || 'Unknown error'));
      }
    } finally {
      setIsLoading(false);
    }
  };

  // Decrypt message content
  const decryptMessageContent = async (encryptedData: string, key: string, metadata: any) => {
    try {
      if (EnvironmentService.isDevelopment()) {
        console.log('Starting decryption...');
        console.log('Key length:', key.length);
        console.log('Has password:', metadata?.has_password);
        console.log('Encrypted data length:', encryptedData.length);
      }
      
      // Parse encrypted data if it's a JSON string
      let parsedData;
      try {
        parsedData = JSON.parse(encryptedData);
        if (EnvironmentService.isDevelopment()) {
          console.log('Parsed encrypted data structure:', {
            hasIv: !!parsedData.iv,
            hasSalt: !!parsedData.salt,
            hasEncryptedData: !!parsedData.encryptedData,
            ivLength: parsedData.iv?.length,
            saltLength: parsedData.salt?.length,
            encryptedDataLength: parsedData.encryptedData?.length
          });
        }
      } catch (parseError) {
        console.error('Failed to parse encrypted data:', parseError);
        setError('Invalid encrypted data format');
        return;
      }
      
      // Validate parsed data structure
      if (!parsedData.iv || !parsedData.salt || !parsedData.encryptedData) {
        setError('Malformed encrypted data - missing required fields');
        return;
      }
      
      // Determine if password is needed
      if (metadata?.has_password && !password) {
        setNeedsPassword(true);
        return;
      }

      // Decrypt the content
      const keyToUse = metadata?.has_password ? password : key;
      
      if (EnvironmentService.isDevelopment()) {
        console.log('Using key type:', metadata?.has_password ? 'password' : 'direct key');
        console.log('Key to use length:', keyToUse.length);
      }
      
      const decrypted = await EncryptionService.decryptMessage(parsedData, keyToUse);
      
      if (EnvironmentService.isDevelopment()) {
        console.log('Decryption successful, content length:', decrypted.length);
      }
      
      setDecryptedContent(decrypted);
      setNeedsPassword(false);
      setError(null);

      toast({
        title: "Message Decrypted",
        description: "Your message has been successfully decrypted.",
      });

    } catch (error: any) {
      console.error('Decryption error:', error);
      
      if (metadata?.has_password) {
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
    await decryptMessageContent(message.encrypted_data, password, message.metadata);
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
                onKeyPress={(e) => e.key === 'Enter' && handleSubmitPassword()}
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
      {showOneTimeWarning && (
        <Card className="border-orange-500">
          <CardContent className="pt-6">
            <div className="flex items-center gap-2 text-orange-600">
              <AlertTriangle className="h-5 w-5" />
              <div>
                <h3 className="font-semibold">One-time Message</h3>
                <p className="text-sm">This message will be permanently deleted after viewing.</p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

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

          {message?.remaining_views !== null && message?.remaining_views !== undefined && (
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
            <div dangerouslySetInnerHTML={{ __html: decryptedContent || 'No content to display' }} />
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
