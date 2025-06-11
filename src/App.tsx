import { Button } from "./components/ui/button";

function App() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-background">
      <div className="container max-w-md p-6 bg-card rounded-lg shadow-lg text-card-foreground">
        <h1 className="text-2xl font-bold mb-4 text-center">Encryptor.link</h1>
        <p className="text-muted-foreground mb-6 text-center">
          Zero-knowledge, end-to-end encrypted messaging service
        </p>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Button variant="default">New Message</Button>
            <Button variant="outline">Open Message</Button>
          </div>
        </div>
        <p className="text-xs mt-6 text-center text-muted-foreground">
          Your data never leaves your browser unencrypted
        </p>
      </div>
    </div>
  );
}

export default App;
