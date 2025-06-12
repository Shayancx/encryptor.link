import React, { useCallback } from 'react';
import { useDropzone } from 'react-dropzone';
import { Upload } from 'lucide-react';
import { cn } from '@/lib/utils';

interface DropzoneProps {
  onDrop: (acceptedFiles: File[]) => void;
  maxSize?: number;
  maxFiles?: number;
  className?: string;
}

export function Dropzone({ 
  onDrop, 
  maxSize = 1000 * 1024 * 1024, // 1GB default
  maxFiles = 10,
  className 
}: DropzoneProps) {
  const handleDrop = useCallback((acceptedFiles: File[]) => {
    onDrop(acceptedFiles);
  }, [onDrop]);

  const { 
    getRootProps, 
    getInputProps, 
    isDragActive,
    isDragReject,
    fileRejections
  } = useDropzone({
    onDrop: handleDrop,
    maxSize,
    maxFiles,
    // Accept all file types
    accept: undefined
  });

  const isFileTooLarge = 
    fileRejections.length > 0 && 
    fileRejections.some(({ errors }) => 
      errors.some(e => e.code === 'file-too-large')
    );

  const tooManyFiles = 
    fileRejections.length > 0 && 
    fileRejections.some(({ errors }) => 
      errors.some(e => e.code === 'too-many-files')
    );

  return (
    <div 
      {...getRootProps()} 
      className={cn(
        "border-2 border-dashed rounded-lg p-6 cursor-pointer transition-colors flex flex-col items-center justify-center text-sm",
        isDragActive ? "border-primary bg-primary/5" : "border-border",
        isDragReject || isFileTooLarge || tooManyFiles ? "border-destructive bg-destructive/5" : "",
        className
      )}
    >
      <input {...getInputProps()} />
      
      <div className="flex flex-col items-center justify-center gap-2 text-center">
        <Upload className="w-8 h-8 text-muted-foreground" />
        
        {isDragActive ? (
          <p className="text-primary">Drop the files here ...</p>
        ) : (
          <p className="text-muted-foreground">Drag & drop files here, or click to select files</p>
        )}
        
        {isFileTooLarge && (
          <p className="text-destructive">File is too large (max {maxSize / 1024 / 1024}MB)</p>
        )}
        
        {tooManyFiles && (
          <p className="text-destructive">Too many files (max {maxFiles} files)</p>
        )}
        
        <p className="text-xs text-muted-foreground">
          All file types accepted • Files are encrypted before upload
        </p>
        <p className="text-xs text-muted-foreground">
          Max file size: {maxSize / 1024 / 1024}MB | Max files: {maxFiles}
        </p>
      </div>
    </div>
  );
}
