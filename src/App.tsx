import React from 'react';
import { ThemeProvider } from './providers/theme-provider';
import { ThemeToggle } from './components/theme/theme-toggle';
import { Button } from './components/ui/button';
import { NewMessage } from './components/message/new-message';
import { OpenMessage } from './components/message/open-message';
import { useAppStore } from './store/app-store';
import { ApiTest } from './components/ApiTest';

function App() {
  const { 
    isCreatingMessage, 
    isViewingMessage,
    startCreatingMessage,
    startViewingMessage,
    error
  } = useAppStore();

  return (
    <ThemeProvider defaultTheme="system" storageKey="encryptor-theme">
      <div className="min-h-screen flex flex-col bg-background">
        {/* Header */}
        <header className="border-b border-border">
          <div className="container flex justify-between items-center py-4">
            <h1 className="text-2xl font-bold">Encryptor.link</h1>
            <ThemeToggle />
          </div>
        </header>

        {/* Main Content */}
        <main className="flex-1 container py-8 flex flex-col items-center">
          {error && (
            <div className="bg-destructive/15 text-destructive px-4 py-2 rounded-md mb-4 w-full max-w-md">
              {error}
            </div>
          )}
          
          {!isCreatingMessage && !isViewingMessage && (
            <div className="text-center space-y-6 max-w-md w-full p-6 bg-card rounded-lg shadow-lg">
              <div>
                <h2 className="text-xl font-bold mb-2">End-to-end encrypted messaging</h2>
                <p className="text-muted-foreground mb-6">
                  Zero-knowledge, end-to-end encrypted messaging service that lets you share self-destructing messages and files with no accounts required.
                </p>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <Button onClick={startCreatingMessage} className="w-full">
                  New Message
                </Button>
                <Button variant="outline" onClick={startViewingMessage} className="w-full">
                  Open Message
                </Button>
              </div>
              
              {/* API Connection Test */}
              <div className="mt-8">
                <ApiTest />
              </div>
              
              <p className="text-xs text-muted-foreground mt-6">
                Your data never leaves your browser unencrypted
              </p>
            </div>
          )}

          {isCreatingMessage && <NewMessage />}
          {isViewingMessage && <OpenMessage />}
        </main>

        {/* Footer */}
        <footer className="border-t border-border py-4">
          <div className="container">
            <div className="flex justify-center text-sm text-muted-foreground">
              © {new Date().getFullYear()} Encryptor.link — Secure Messaging
            </div>
          </div>
        </footer>
      </div>
    </ThemeProvider>
  );
}

export default App;
