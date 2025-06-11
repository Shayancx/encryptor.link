import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { TiptapEditor } from '@/components/editor/tiptap-editor';
import { Dropzone } from '@/components/file-upload/dropzone';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { QRGenerator } from '@/components/qrcode/qr-generator';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Lock, Eye, Clock, KeyRound, QrCode, AlertCircle } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { useToast } from '@/components/ui/use-toast';
import { EncryptionService } from '@/services/encryption-service';
import { ApiService } from '@/services/api-service';
import { EnvironmentService } from '@/config/environment';
import { expirationToMs, viewLimitToNumber } from '@/services/utils';

const expirationOptions = [
  { value: '1h', label: '1 hour' },
  { value: '1d', label: '1 day' },
  { value: '3d', label: '3 days' },
  { value: '7d', label: '7 days' },
  { value: '30d', label: '30 days' },
  { value: 'never', label: 'Never' },
];

const viewLimitOptions = [
  { value: '1', label: '1 view' },
  { value: '3', label: '3 views' },
  { value: '5', label: '5 views' },
  { value: '10', label: '10 views' },
  { value: 'unlimited', label: 'Unlimited' },
];

export function MessageCreator() {
  const [content, setContent] = useState('');
  const [files, setFiles] = useState<File[]>([]);
  const [enablePassword, setEnablePassword] = useState(false);
  const [password, setPassword] = useState('');
  const [expiration, setExpiration] = useState('1d');
  const [viewLimit, setViewLimit] = useState('1');
  const [burnAfterReading, setBurnAfterReading] = useState(true);
  const [generateQR, setGenerateQR] = useState(false);
  const [encryptedLink, setEncryptedLink] = useState<string | null>(null);
  const [isCreating, setIsCreating] = useState(false);
  const { toast } = useToast();

  const handleFilesDrop = (acceptedFiles: File[]) => {
    setFiles(prev => [...prev, ...acceptedFiles]);
  };

  const removeFile = (index: number) => {
    setFiles(prev => prev.filter((_, i) => i !== index));
  };

  const getTotalFileSize = () => {
    return files.reduce((acc, file) => acc + file.size, 0);
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const handleCreateMessage = async () => {
    // Validate input
    if (!content && files.length === 0) {
      toast({
        title: "Content required",
        description: "Please enter a message or attach a file.",
        variant: "destructive",
      });
      return;
    }

    if (enablePassword && !password) {
      toast({
        title: "Password required",
        description: "Please enter a password for your encrypted message.",
        variant: "destructive",
      });
      return;
    }

    try {
      setIsCreating(true);
      console.log("Starting message encryption and creation...");

      // Encrypt the message
      const encryptionResult = await EncryptionService.encryptMessage(
        content,
        enablePassword ? password : null
      );

      console.log("Message encrypted successfully", { 
        hasKey: !!encryptionResult.key,
        isPasswordProtected: enablePassword 
      });

      // Prepare metadata
      const expiresAt = expirationToMs(expiration);
      const maxViews = viewLimitToNumber(viewLimit);

      // Encrypt files if any
      const encryptedFiles = [];
      for (const file of files) {
        toast({
          title: "Encrypting files...",
          description: `Encrypting ${file.name}...`,
        });

        const encryptedFile = await EncryptionService.encryptFile(
          file,
          enablePassword ? password : null
        );

        encryptedFiles.push({
          data: encryptedFile.encryptedData,
          name: file.name,
          type: file.type,
          size: file.size,
          metadata: encryptedFile.metadata,
          key: encryptedFile.key // Only for non-password files
        });
      }

      const metadata = {
        expires_at: expiresAt ? new Date(Date.now() + expiresAt).toISOString() : undefined,
        max_views: maxViews,
        burn_after_reading: burnAfterReading,
        has_password: enablePassword,
        files: encryptedFiles.map(f => ({
          name: f.name,
          type: f.type,
          size: f.size,
          metadata: f.metadata
        }))
      };

      console.log("Sending to API:", {
        data: {
          encrypted_data: JSON.stringify(encryptionResult.encrypted),
          metadata,
          files: encryptedFiles
        }
      });

      // Create message on the server
      const response = await ApiService.createMessage({
        data: {
          encrypted_data: JSON.stringify(encryptionResult.encrypted),
          metadata,
          files: encryptedFiles
        }
      });

      console.log("API response:", response);

      // Generate the shareable link
      const shareableLink = EncryptionService.createShareableLink(
        response.id,
        encryptionResult.key // Only includes key for non-password messages
      );
      setEncryptedLink(shareableLink);

      toast({
        title: "Message Created",
        description: enablePassword ? 
          "Your password-protected message has been created. Share the link and password separately!" :
          "Your encrypted message has been created successfully!",
      });

      // Show warning for password-protected messages
      if (enablePassword) {
        toast({
          title: "Important Security Note",
          description: "Never share the password in the same channel as the link. Send them separately for maximum security.",
          variant: "default",
        });
      }
    } catch (error) {
      console.error('Error creating message:', error);
      toast({
        title: "Error",
        description: error.error || "Failed to create encrypted message. Please try again.",
        variant: "destructive",
      });
    } finally {
      setIsCreating(false);
    }
  };

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold tracking-tight">Create Encrypted Message</h2>
      
      <div className="space-y-6">
        <div>
          <Label htmlFor="message-content">Message</Label>
          <TiptapEditor 
            content={content} 
            onChange={setContent} 
            placeholder="Enter your secure message here..."
          />
        </div>
        
        <div className="grid gap-6 md:grid-cols-2">
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-2 mb-2">
                <Lock className="h-4 w-4 text-primary" />
                <Label htmlFor="password-protection" className="text-base font-medium">Password Protection</Label>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <div className="text-sm text-muted-foreground">
                    Require a password to access this content
                  </div>
                </div>
                <Switch 
                  id="password-protection" 
                  checked={enablePassword}
                  onCheckedChange={setEnablePassword}
                />
              </div>
              
              {enablePassword && (
                <div className="mt-4 space-y-3">
                  <div>
                    <Label htmlFor="password">Password</Label>
                    <div className="flex gap-2 mt-1">
                      <Input 
                        id="password" 
                        type="password" 
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        placeholder="Enter a strong password"
                      />
                    </div>
                  </div>
                  <div className="p-3 bg-amber-50 dark:bg-amber-900/20 rounded-md">
                    <div className="flex gap-2">
                      <AlertCircle className="h-4 w-4 text-amber-600 dark:text-amber-400 flex-shrink-0 mt-0.5" />
                      <div className="text-sm text-amber-800 dark:text-amber-200">
                        <p className="font-medium">Security Notice</p>
                        <p className="mt-1">The password will NOT be included in the link. You must share it separately through a secure channel.</p>
                      </div>
                    </div>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-2 mb-2">
                <Clock className="h-4 w-4 text-primary" />
                <Label className="text-base font-medium">Expiration Time</Label>
              </div>
              
              <div className="space-y-1 mb-4">
                <div className="text-sm text-muted-foreground">
                  Message expires automatically after
                </div>
              </div>
              
              <Select value={expiration} onValueChange={setExpiration}>
                <SelectTrigger>
                  <SelectValue placeholder="Select expiration" />
                </SelectTrigger>
                <SelectContent>
                  {expirationOptions.map(option => (
                    <SelectItem key={option.value} value={option.value}>
                      {option.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-2 mb-2">
                <Eye className="h-4 w-4 text-primary" />
                <Label className="text-base font-medium">View Limit</Label>
              </div>
              
              <div className="space-y-1 mb-4">
                <div className="text-sm text-muted-foreground">
                  Self-destruct after this many views
                </div>
              </div>
              
              <Select value={viewLimit} onValueChange={setViewLimit}>
                <SelectTrigger>
                  <SelectValue placeholder="Select view limit" />
                </SelectTrigger>
                <SelectContent>
                  {viewLimitOptions.map(option => (
                    <SelectItem key={option.value} value={option.value}>
                      {option.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center gap-2 mb-2">
                <KeyRound className="h-4 w-4 text-primary" />
                <Label htmlFor="burn-after-reading" className="text-base font-medium">Burn After Reading</Label>
              </div>
              
              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <div className="text-sm text-muted-foreground">
                    Delete immediately after first view
                  </div>
                </div>
                <Switch 
                  id="burn-after-reading" 
                  checked={burnAfterReading}
                  onCheckedChange={setBurnAfterReading}
                />
              </div>
            </CardContent>
          </Card>
        </div>
        
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center gap-2 mb-2">
              <QrCode className="h-4 w-4 text-primary" />
              <Label htmlFor="generate-qr" className="text-base font-medium">Generate QR Code</Label>
            </div>
            
            <div className="flex items-center justify-between">
              <div className="space-y-1">
                <div className="text-sm text-muted-foreground">
                  Create a QR code for the encrypted link
                </div>
              </div>
              <Switch 
                id="generate-qr" 
                checked={generateQR}
                onCheckedChange={setGenerateQR}
              />
            </div>
            
            {generateQR && encryptedLink && (
              <div className="mt-4 flex justify-center">
                <QRGenerator value={encryptedLink} />
              </div>
            )}
          </CardContent>
        </Card>
        
        <div className="space-y-2">
          <Label>Attach Files (optional, max 100MB total)</Label>
          <Dropzone onDrop={handleFilesDrop} maxSize={100 * 1024 * 1024} />
          
          {files.length > 0 && (
            <div className="mt-4 space-y-2">
              <div className="text-sm font-medium">
                Attached Files ({formatFileSize(getTotalFileSize())})
              </div>
              <div className="space-y-2">
                {files.map((file, index) => (
                  <div key={index} className="flex items-center justify-between bg-secondary rounded-md p-2">
                    <span className="truncate text-sm">{file.name} ({formatFileSize(file.size)})</span>
                    <Button 
                      variant="ghost" 
                      size="sm"
                      onClick={() => removeFile(index)}
                    >
                      Remove
                    </Button>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
        
        {encryptedLink ? (
          <div className="space-y-4">
            <div className="bg-secondary p-4 rounded-md">
              <Label className="block mb-2">Your Encrypted Link</Label>
              <div className="flex items-center gap-2">
                <Input 
                  readOnly 
                  value={encryptedLink}
                  className="font-mono"
                />
                <Button
                  onClick={() => {
                    navigator.clipboard.writeText(encryptedLink);
                    toast({
                      title: "Link copied",
                      description: "Encrypted link copied to clipboard",
                    });
                  }}
                >
                  Copy
                </Button>
              </div>
              <p className="mt-2 text-sm text-muted-foreground">
                {enablePassword ? 
                  "Share this link with the recipient. Remember to send the password separately!" :
                  "Share this link securely with the recipient. The decryption key is included in the link."
                }
              </p>
            </div>
            
            {enablePassword && (
              <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-md">
                <h4 className="font-medium mb-2">How to share securely:</h4>
                <ol className="list-decimal list-inside space-y-1 text-sm">
                  <li>Copy and send the link above through one channel (e.g., email)</li>
                  <li>Send the password through a different channel (e.g., SMS, phone call)</li>
                  <li>Never include both in the same message</li>
                </ol>
              </div>
            )}
          </div>
        ) : (
          <Button 
            onClick={handleCreateMessage} 
            className="w-full"
            disabled={isCreating}
          >
            {isCreating ? 'Creating...' : 'Create Encrypted Message'}
          </Button>
        )}
      </div>
    </div>
  );
}
