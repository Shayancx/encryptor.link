import React from 'react';
import Button from './ui/button';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from './ui/card';

const App = () => {
  return (
    <div className="container mt-6">
      <h1 className="text-2xl font-bold mb-4">EncryptorLink</h1>
      
      <Card className="max-w-md mx-auto">
        <CardHeader>
          <CardTitle>Secure Messaging</CardTitle>
          <CardDescription>
            Zero-knowledge, end-to-end encrypted messaging
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p>
            Share self-destructing messages and files with no accounts required. 
            Your data never leaves your browser unencrypted.
          </p>
        </CardContent>
        <CardFooter className="flex justify-between">
          <Button variant="outline">Learn More</Button>
          <Button>Get Started</Button>
        </CardFooter>
      </Card>

      <div className="mt-6 text-center">
        <p className="text-sm text-muted-foreground">
          EncryptorLink - Secure by design
        </p>
      </div>
    </div>
  );
};

export default App;
