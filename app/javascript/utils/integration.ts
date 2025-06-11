import { prepareFilesForUpload, uploadEncryptedData } from './fileUpload';

export async function createEncryptedLink(
  message: string,
  files: File[],
  expiresIn: number = 7 * 24 * 60 * 60 // Default: 7 days in seconds
) {
  try {
    // 1. Encrypt the message if present
    let encryptedPayload = "";
    if (message.trim()) {
      // Simple encryption for demonstration
      encryptedPayload = btoa(message);
    }
    
    // 2. Prepare files if any
    const preparedFiles = files.length > 0 ? await prepareFilesForUpload(files) : [];
    
    // 3. Upload everything to the server
    const response = await uploadEncryptedData(encryptedPayload, preparedFiles);
    
    // 4. Generate link from the response
    const linkId = response.id;
    const url = new URL(`${window.location.origin}/s/${linkId}`);
    
    // Add expiration if specified
    if (expiresIn) {
      url.searchParams.append('expires', expiresIn.toString());
    }
    
    return url.toString();
  } catch (error) {
    console.error('Failed to create encrypted link:', error);
    throw new Error('Failed to create encrypted link. Please try again.');
  }
}
