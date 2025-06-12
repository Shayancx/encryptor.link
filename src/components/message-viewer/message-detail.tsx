import React, { useState, useEffect } from 'react';
import { useParams, useLocation } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent } from '@/components/ui/card';
import { Lock, AlertTriangle, Eye, Clock, CheckCircle, Download } from 'lucide-react';
import { useToast } from '@/components/ui/use-toast';
import { ApiService } from '@/services/api-service';
import { EncryptionService } from '@/services/encryption-service';
import { EnvironmentService } from '@/config/environment';
import { getTimeRemaining, formatFileSize } from '@/services/utils';

export function MessageDetail() {
  const { id } = useParams<{ id: string }>();
  const location = useLocation();
  const [password, setPassword] = useState('');
  const [needsPassword, setNeedsPassword] = useState(false);
  const [message, setMessage] = useState<any>(null);
  const [decryptedContent, setDecryptedContent] = useState<string | null>(null);
  const [decryptedFiles, setDecryptedFiles] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isDecryptingFile, setIsDecryptingFile] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [timeRemaining, setTimeRemaining] = useState<any>(null);
  const [showOneTimeWarning, setShowOneTimeWarning] = useState(false);
  const [hasViewed, setHasViewed] = useState(false);
  const { toast } = useToast();

  // Extract key from URL fragment (only for non-password messages)
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
      if (data.metadata?.remaining_views === 1 || data.metadata?.burn_after_reading) {
        setShowOneTimeWarning(true);
      }

      // Check if password protected
      if (data.metadata?.has_password) {
        setNeedsPassword(true);
      } else {
        // Try to decrypt with key from URL fragment
        const key = getKeyFromFragment();
        if (key) {
          await decryptMessageContent(data.encrypted_data, key, data.metadata);
        } else {
          setError('No decryption key provided in URL');
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
  const decryptMessageContent = async (encryptedData: string, keyOrPassword: string, metadata: any) => {
    try {
      if (EnvironmentService.isDevelopment()) {
        console.log('Starting decryption...');
        console.log('Is password protected:', metadata?.has_password);
      }
      
      // Parse encrypted data
      const parsedData = JSON.parse(encryptedData);
      
      // Decrypt the content
      const decrypted = await EncryptionService.decryptMessage(parsedData, keyOrPassword);
      
      if (EnvironmentService.isDevelopment()) {
        console.log('Decryption successful');
      }
      
      setDecryptedContent(decrypted);
      setNeedsPassword(false);
      setError(null);

      // Decrypt file metadata if present
      if (metadata?.files && metadata.files.length > 0) {
        const decryptedFilesList = metadata.files.map((file: any) => ({
          ...file,
          ready: true,
          keyOrPassword: keyOrPassword
        }));
        setDecryptedFiles(decryptedFilesList);
      }

      // Track view after successful decryption (only once)
      if (!hasViewed) {
        try {
          await ApiService.viewMessage(id!);
          setHasViewed(true);
          if (EnvironmentService.isDevelopment()) {
            console.log('View tracked successfully');
          }
        } catch (viewError) {
          console.warn('Failed to track view:', viewError);
        }
      }

      toast({
        title: "Message Decrypted",
        description: "Your message has been successfully decrypted.",
      });

    } catch (error: any) {
      console.error('Decryption error:', error);
      
      if (metadata?.has_password) {
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

  // Handle file download
  const handleDownloadFile = async (file: any) => {
    try {
      setIsDecryptingFile(file.name);
      
      if (EnvironmentService.isDevelopment()) {
        console.log('Downloading file:', file.name);
      }
      
      // Get the file data from the server
      const fileResponse = await ApiService.getFile(id!, file.name);
      
      if (!fileResponse || !fileResponse.data) {
        throw new Error('No file data received');
      }

      if (EnvironmentService.isDevelopment()) {
        console.log('File data received, decrypting...');
      }

      // Decrypt the file
      const decryptedBlob = await EncryptionService.decryptFile(
        fileResponse.data,
        file.metadata || fileResponse.metadata,
        file.keyOrPassword
      );

      // Download the file
      EncryptionService.downloadDecryptedFile(decryptedBlob, file.name);

      toast({
        title: "File Downloaded",
        description: `${file.name} has been decrypted and downloaded.`,
      });
    } catch (error: any) {
      console.error('Error downloading file:', error);
      toast({
        title: "Download Failed",
        description: error.message || "Failed to download and decrypt file",
        variant: "destructive",
      });
    } finally {
      setIsDecryptingFile(null);
    }
  };

  // Update time remaining countdown
  useEffect(() => {
    if (!message?.metadata?.expires_at) return;
    
    const expiresAt = new Date(message.metadata.expires_at);
    
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
  }, [message?.metadata?.expires_at]);

  // Fetch message on component mount
  useEffect(() => {
    fetchMessage();
  }, [id]);

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="text-center">
          <div className="animate-spin h-8 w-8 border-4 border-primary border-t-transparent rounded-full mx-auto mb-4"></div>
          <p>Loading encrypted message...</p>
        </div>
      </div>
    );
  }

  if (error && !needsPassword) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background p-4">
        <Card className="max-w-md w-full border-destructive">
          <CardContent className="pt-6">
            <div className="flex flex-col items-center text-center gap-4">
              <AlertTriangle className="h-12 w-12 text-destructive" />
              <div>
                <h2 className="text-xl font-bold mb-2">Error</h2>
                <p className="text-muted-foreground">{error}</p>
              </div>
              <Button onClick={() => window.location.href = '/'}>
                Back to Home
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (needsPassword) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background p-4">
        <Card className="max-w-md w-full">
          <CardContent className="pt-6">
            <div className="flex flex-col items-center text-center gap-4">
              <Lock className="h-12 w-12 text-primary" />
              <div>
                <h2 className="text-xl font-bold mb-2">Password Protected</h2>
                <p className="text-muted-foreground">This message is protected with a password.</p>
              </div>
              
              <div className="w-full space-y-4">
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
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <div className="container max-w-4xl py-8">
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

              {message?.metadata?.remaining_views !== null && message?.metadata?.remaining_views !== undefined && (
                <div className="flex items-center gap-2 text-sm text-muted-foreground mb-4">
                  <Eye className="h-4 w-4" />
                  <span>
                    {message.metadata.remaining_views === 1 
                      ? 'This is your last view'
                      : `${message.metadata.remaining_views} views remaining`}
                  </span>
                </div>
              )}

              {decryptedContent && (
                <div className="border rounded-md p-4 prose prose-sm dark:prose-invert max-w-none">
                  <div dangerouslySetInnerHTML={{ __html: decryptedContent }} />
                </div>
              )}

              {decryptedFiles.length > 0 && (
                <div className="space-y-3">
                  <h3 className="font-medium">Attached Files ({decryptedFiles.length})</h3>
                  <div className="space-y-2">
                    {decryptedFiles.map((file, index) => (
                      <div key={index} className="flex items-center justify-between p-3 border rounded-md">
                        <div>
                          <p className="font-medium">{file.name}</p>
                          <p className="text-sm text-muted-foreground">
                            {file.type || 'Unknown type'} • {formatFileSize(file.size)}
                          </p>
                        </div>
                        <Button
                          size="sm"
                          onClick={() => handleDownloadFile(file)}
                          disabled={isDecryptingFile === file.name}
                        >
                          {isDecryptingFile === file.name ? (
                            <>Decrypting...</>
                          ) : (
                            <>
                              <Download className="h-4 w-4 mr-1" />
                              Download
                            </>
                          )}
                        </Button>
                      </div>
                    ))}
                  </div>
                </div>
              )}
              
              <div className="flex justify-end pt-4">
                <Button onClick={() => window.location.href = '/'}>
                  Back to Home
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
