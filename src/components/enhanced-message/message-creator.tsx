import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { TiptapEditor } from '@/components/editor/tiptap-editor';
import { Dropzone } from '@/components/file-upload/dropzone';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { QRGenerator } from '@/components/qrcode/qr-generator';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import { 
  Lock, Eye, Clock, KeyRound, QrCode
} from 'lucide-react';
import { Card, CardContent } from '@/components/ui/card';
import { cn } from '@/lib/utils';
import { useToast } from '@/components/ui/use-toast';

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

  const handleCreateMessage = () => {
    // This would typically call your encryption service
    if (!content && files.length === 0) {
      toast({
        title: "Content required",
        description: "Please enter a message or attach a file.",
        variant: "destructive",
      });
      return;
    }
    
    // Simulate creating an encrypted link
    const simulatedLink = `https://encryptor.link/m/${Math.random().toString(36).substring(2, 15)}`;
    setEncryptedLink(simulatedLink);
    
    toast({
      title: "Message Created",
      description: "Your encrypted message has been created successfully!",
    });
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
                <div className="mt-4">
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
          <Label>Attach Files (optional, max 10MB total)</Label>
          <Dropzone onDrop={handleFilesDrop} maxSize={10 * 1024 * 1024} />
          
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
              Share this link securely with the recipient. The message will be encrypted end-to-end.
            </p>
          </div>
        ) : (
          <Button onClick={handleCreateMessage} className="w-full">
            Create Encrypted Message
          </Button>
        )}
      </div>
    </div>
  );
}
