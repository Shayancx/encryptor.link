import React from 'react';
import { Button } from '@/components/ui/button';
import { Link } from 'react-router-dom';

export function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center h-[70vh] text-center px-4">
      <h1 className="text-4xl font-bold mb-4">404</h1>
      <p className="text-xl mb-8">Page not found</p>
      <p className="text-muted-foreground mb-8 max-w-md">
        The page you're looking for doesn't exist or has been moved.
      </p>
      <Button asChild>
        <Link to="/">Go Home</Link>
      </Button>
    </div>
  );
}
