import { encryptFile } from './encryption';

export async function prepareFilesForUpload(files: File[]): Promise<any[]> {
  const encryptedFiles = [];
  
  for (const file of files) {
    const encryptedData = await encryptFile(file);
    encryptedFiles.push({
      encrypted_file: encryptedData.encryptedContent,
      content_type: file.type,
      size: file.size
    });
  }
  
  return encryptedFiles;
}

export async function uploadEncryptedData(payload = "", files = []) {
  try {
    const response = await fetch('/api/encrypted_files', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        payload,
        files
      })
    });
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('Error uploading encrypted data:', error);
    throw error;
  }
}
