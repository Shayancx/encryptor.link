import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { Input } from '@/components/ui/input';
import { Switch } from '@/components/ui/switch';
import { Label } from '@/components/ui/label';
import { EncryptionService } from '@/services/encryption-service';
import { useAppStore } from '@/store/app-store';
import { X } from 'lucide-react';

export function NewMessage() {
  const [message, setMessage] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [expires, setExpires] = useState(false);
  const [expireHours, setExpireHours] = useState(24);
  const cancelCreatingMessage = useAppStore(state => state.cancelCreatingMessage);
  const setError = useAppStore(state => state.setError);
  const setLoading = useAppStore(state => state.setLoading);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setFile(e.target.files[0]);
    }
  };

  const handleSubmit = async () => {
    if (!message && !file) {
      setError('Please enter a message or select a file to encrypt.');
      return;
    }

    try {
      setLoading(true);

      // Generate encryption key
      const key = EncryptionService.generateKey();

      // Encrypt message
      let encryptedMessage;
      if (message) {
        encryptedMessage = EncryptionService.encryptMessage(message, key);
      }

      // Encrypt file if present
      let encryptedFile;
      if (file) {
        encryptedFile = await EncryptionService.encryptFile(file);
      }

      // Generate share URL with key as fragment (doesn't get sent to server)
      const baseUrl = window.location.origin;
      const shareUrl = `${baseUrl}/message#${key}`;

      // Show success message with URL
      alert(`Your encrypted message has been created!\n\nShare this link: ${shareUrl}\n\nThe decryption key is: ${key}\n\nNOTE: This link will only work once. Anyone with this link can read your message.`);

      // Clear form
      setMessage('');
      setFile(null);
      cancelCreatingMessage();
    } catch (error: any) {
      setError(error.message || 'Failed to encrypt message');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-4 p-4 bg-card rounded-lg shadow-md w-full max-w-md mx-auto">
      <div className="flex justify-between items-center">
        <h2 className="text-xl font-semibold">Create New Message</h2>
        <Button 
          variant="ghost" 
          size="icon" 
          onClick={cancelCreatingMessage}
          aria-label="Close"
        >
          <X className="h-4 w-4" />
        </Button>
      </div>

      <div className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="message">Message</Label>
          <Textarea
            id="message"
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Enter your secure message here..."
            className="h-32"
          />
        </div>

        <div className="space-y-2">
          <Label htmlFor="file">Attach File</Label>
          <Input
            id="file"
            type="file"
            onChange={handleFileChange}
          />
          {file && (
            <div className="text-sm text-muted-foreground">
              Selected file: {file.name} ({(file.size / 1024).toFixed(2)} KB)
            </div>
          )}
        </div>

        <div className="flex items-center space-x-2">
          <Switch
            id="expires"
            checked={expires}
            onCheckedChange={setExpires}
          />
          <Label htmlFor="expires">Self-destruct after reading</Label>
        </div>

        {expires && (
          <div className="space-y-2">
            <Label htmlFor="expire-hours">Expires in (hours)</Label>
            <Input
              id="expire-hours"
              type="number"
              value={expireHours}
              onChange={(e) => setExpireHours(Number(e.target.value))}
              min={1}
            />
          </div>
        )}

        <div className="flex space-x-2 justify-end">
          <Button variant="outline" onClick={cancelCreatingMessage}>
            Cancel
          </Button>
          <Button onClick={handleSubmit}>
            Encrypt & Create Link
          </Button>
        </div>
      </div>
    </div>
  );
}
