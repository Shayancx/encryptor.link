import React, { useState } from 'react';
import { ThemeProvider } from './providers/theme-provider';
import { ThemeToggle } from './components/theme/theme-toggle';
import { Button } from './components/ui/button';
import { MessageCreator } from './components/enhanced-message/message-creator';
import { Toaster } from './components/ui/toaster';
import { Check, Link } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { EnvironmentService } from './config/environment';
import { EncryptionService } from './services/encryption-service'; 

export function App() {
  const [mode, setMode] = useState<'create' | 'open'>('create');
  const [linkToOpen, setLinkToOpen] = useState('');
  const navigate = useNavigate();
  
  const handleOpenLink = () => {
    if (!linkToOpen.trim()) {
      alert('Please enter a link to open');
      return;
    }

    try {
      // Try to parse as full URL
      const parsedLink = EncryptionService.parseShareableLink(linkToOpen);
      if (parsedLink) {
        navigate(`/message/${parsedLink.messageId}#${parsedLink.key}`);
        return;
      }

      // If not a full URL, try to parse as just an ID + key
      if (linkToOpen.includes('#')) {
        const [id, key] = linkToOpen.split('#');
        if (id && key) {
          navigate(`/message/${id}#${key}`);
          return;
        }
      }

      // Invalid link format
      alert('Invalid link format. Please enter a complete encrypted message link.');
    } catch (error) {
      console.error('Error parsing link:', error);
      alert('Failed to parse the link. Please enter a valid encrypted message link.');
    }
  };

  return (
    <ThemeProvider defaultTheme="dark" storageKey="encryptor-theme">
      <div className="min-h-screen flex flex-col bg-background">
        {/* Header */}
        <header className="border-b border-border">
          <div className="container flex justify-between items-center py-4">
            <div className="flex items-center gap-2">
              <h1 className="text-2xl font-bold tracking-tight">encryptor.link</h1>
              {EnvironmentService.isDevelopment() && (
                <span className="text-xs bg-primary/20 text-primary px-2 py-1 rounded-full">
                  DEV
                </span>
              )}
            </div>
            <div className="flex items-center gap-4">
              <Button 
                variant="link" 
                onClick={() => setMode('create')} 
                className={mode === 'create' ? 'text-primary' : 'text-muted-foreground'}
              >
                Create
              </Button>
              <Button 
                variant="link" 
                onClick={() => setMode('open')}
                className={mode === 'open' ? 'text-primary' : 'text-muted-foreground'}
              >
                Open
              </Button>
              <ThemeToggle />
            </div>
          </div>
        </header>

        {/* Main Content */}
        <main className="flex-1">
          <div className="container max-w-4xl py-8">
            {mode === 'create' ? (
              <MessageCreator />
            ) : (
              <div className="space-y-6">
                <h2 className="text-2xl font-bold tracking-tight">Open Encrypted Message</h2>
                <div className="bg-card border rounded-lg p-6 space-y-6">
                  <p className="text-muted-foreground">
                    Enter the encrypted link you received to view the message. All decryption happens in your browser.
                  </p>
                  
                  <div className="flex items-center gap-2">
                    <div className="relative flex-1">
                      <Link className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
                      <input
                        type="text"
                        value={linkToOpen}
                        onChange={(e) => setLinkToOpen(e.target.value)}
                        placeholder={`${EnvironmentService.getBaseUrl()}/message/abc123#key456`}
                        className="w-full pl-10 py-2 rounded-md border border-input bg-background"
                      />
                    </div>
                    <Button onClick={handleOpenLink}>
                      <Check className="mr-2 h-4 w-4" /> Open
                    </Button>
                  </div>
                  
                  <div className="bg-muted p-4 rounded-md text-sm">
                    <p className="font-medium mb-2">End-to-end encryption</p>
                    <p>Messages are decrypted directly in your browser. No one, not even us, can access your private data.</p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </main>

        {/* Footer */}
        <footer className="border-t border-border py-6">
          <div className="container">
            <div className="flex flex-col md:flex-row justify-between items-center gap-4">
              <div className="text-sm text-muted-foreground">
                © {new Date().getFullYear()} Encryptor.link — Secure, end-to-end encrypted messaging
              </div>
              <div className="flex gap-4 text-sm">
                <a href="#" className="text-muted-foreground hover:text-foreground">Privacy</a>
                <a href="#" className="text-muted-foreground hover:text-foreground">Terms</a>
                <a href="#" className="text-muted-foreground hover:text-foreground">About</a>
                <a href="#" className="text-muted-foreground hover:text-foreground">GitHub</a>
              </div>
            </div>
          </div>
        </footer>
        
        <Toaster />
      </div>
    </ThemeProvider>
  );
}
