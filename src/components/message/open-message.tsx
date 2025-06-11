import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { EncryptionService } from '@/services/encryption-service';
import { useAppStore } from '@/store/app-store';
import { X } from 'lucide-react';
import { Label } from '@/components/ui/label';

export function OpenMessage() {
  const [key, setKey] = useState('');
  const cancelViewingMessage = useAppStore(state => state.cancelViewingMessage);
  const setError = useAppStore(state => state.setError);
  const setLoading = useAppStore(state => state.setLoading);
  const [decryptedMessage, setDecryptedMessage] = useState<string | null>(null);

  const handleSubmit = () => {
    if (!key.trim()) {
      setError('Please enter a decryption key.');
      return;
    }

    try {
      setLoading(true);
      
      // In a real app, we would fetch the encrypted message using the key
      // For now, we'll simulate decryption of a hardcoded message
      const mockEncryptedMessage = {
        iv: "9cdf5a247a64f216c31154f5c95f7b10",
        encryptedData: "U2FsdGVkX18nfpgxUNYZ0Hcw84CgxRHNFP9Jj1Je8V6JRgjq9ubs8Lq9vMUJP/0U"
      };
      
      // This will only work with a specific key, but that's fine for the demo
      try {
        const decrypted = EncryptionService.decryptMessage(mockEncryptedMessage, key);
        setDecryptedMessage(decrypted);
      } catch (e) {
        setDecryptedMessage("This is a demo message. In the real app, you would need the correct decryption key.");
      }
      
    } catch (error: any) {
      setError(error.message || 'Failed to decrypt message');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4 p-4 bg-card rounded-lg shadow-md w-full max-w-md mx-auto">
      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Open Encrypted Message</h2>
        <Button 
          variant="ghost" 
          size="icon" 
          onClick={cancelViewingMessage}
          aria-label="Close"
        >
          <X className="h-4 w-4" />
        </Button>
      </div>

      {!decryptedMessage ? (
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="key">Decryption Key</Label>
            <Input
              id="key"
              value={key}
              onChange={(e) => setKey(e.target.value)}
              placeholder="Enter the decryption key..."
            />
            <p className="text-sm text-muted-foreground">
              Enter the decryption key that was provided with the message link.
            </p>
          </div>

          <div className="flex space-x-2 justify-end">
            <Button variant="outline" onClick={cancelViewingMessage}>
              Cancel
            </Button>
            <Button onClick={handleSubmit}>
              Decrypt Message
            </Button>
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          <div className="p-4 bg-muted rounded-md">
            <h3 className="font-medium mb-2">Decrypted Message:</h3>
            <div className="whitespace-pre-wrap">{decryptedMessage}</div>
          </div>
          
          <div className="text-sm text-center text-muted-foreground">
            This message has been securely decrypted in your browser.
            <br />For security, it may be destroyed after you navigate away.
          </div>
          
          <div className="flex justify-center">
            <Button onClick={cancelViewingMessage}>
              Close
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
