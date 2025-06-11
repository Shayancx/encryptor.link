import React, { useState, useCallback } from 'react';
import { encryptFile } from '../services/encryptionService';
import { createMessage } from '../services/apiService';

interface FileUploaderProps {
  encryptionKey: string;
  onLinkCreated: (link: string) => void;
  onError: (error: string) => void;
}

const FileUploader: React.FC<FileUploaderProps> = ({ encryptionKey, onLinkCreated, onError }) => {
  const [files, setFiles] = useState<File[]>([]);
  const [message, setMessage] = useState<string>('');
  const [isUploading, setIsUploading] = useState<boolean>(false);
  const [progress, setProgress] = useState<number>(0);

  const handleFileChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setFiles(Array.from(e.target.files));
    }
  }, []);

  const handleMessageChange = useCallback((e: React.ChangeEvent<HTMLTextAreaElement>) => {
    setMessage(e.target.value);
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!message && files.length === 0) {
      onError('Please add a message or at least one file');
      return;
    }
    
    setIsUploading(true);
    setProgress(0);
    
    try {
      // Encrypt message if provided
      let encryptedPayload = '';
      if (message) {
        // Import encryptMessage dynamically to avoid circular dependencies
        const { encryptMessage } = await import('../services/encryptionService');
        encryptedPayload = encryptMessage(message, encryptionKey);
      }
      
      // Process files if any
      const encryptedFiles = [];
      const totalFiles = files.length;
      
      for (let i = 0; i < totalFiles; i++) {
        const encryptedFile = await encryptFile(files[i], encryptionKey);
        encryptedFiles.push(encryptedFile);
        setProgress(((i + 1) / totalFiles) * 100);
      }
      
      // Send to server
      const result = await createMessage(encryptedPayload, encryptedFiles);
      
      if (result.error) {
        throw new Error(result.error);
      }
      
      if (result.data) {
        // Create shareable link with encryption key in the fragment
        const baseUrl = `${window.location.origin}/s/${result.data.id}`;
        const shareableLink = `${baseUrl}#${encryptionKey}`;
        onLinkCreated(shareableLink);
        
        // Clear form
        setFiles([]);
        setMessage('');
      }
    } catch (error) {
      console.error('Error uploading files:', error);
      onError(error instanceof Error ? error.message : 'Failed to create encrypted link');
    } finally {
      setIsUploading(false);
    }
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <div className="form-group">
        <label>Message (optional):</label>
        <textarea
          value={message}
          onChange={handleMessageChange}
          className="form-control"
          placeholder="Enter your secure message here..."
          rows={5}
          disabled={isUploading}
        />
      </div>
      
      <div className="form-group">
        <label>Files (optional):</label>
        <input
          type="file"
          onChange={handleFileChange}
          className="form-control"
          multiple
          disabled={isUploading}
        />
        <small className="form-text text-muted">
          Select one or more files to encrypt and share
        </small>
        {files.length > 0 && (
          <div className="mt-2">
            <strong>Selected files:</strong>
            <ul>
              {files.map((file, index) => (
                <li key={index}>
                  {file.name} ({(file.size / 1024).toFixed(2)} KB)
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>
      
      {isUploading && (
        <div className="progress">
          <div
            className="progress-bar"
            role="progressbar"
            style={{ width: `${progress}%` }}
            aria-valuenow={progress}
            aria-valuemin={0}
            aria-valuemax={100}
          >
            {progress.toFixed(0)}%
          </div>
        </div>
      )}
      
      <button
        type="submit"
        className="btn btn-primary mt-3"
        disabled={isUploading}
      >
        {isUploading ? 'Creating Encrypted Link...' : 'Create Encrypted Link'}
      </button>
    </form>
  );
};

export default FileUploader;
