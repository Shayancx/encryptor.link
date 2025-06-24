/**
 * Safe base64 encoding utilities that handle Unicode properly
 */

export function safeBase64Encode(str: string): string {
  // Convert string to UTF-8 bytes then to base64
  const utf8Bytes = new TextEncoder().encode(str);
  const binaryString = Array.from(utf8Bytes)
    .map(byte => String.fromCharCode(byte))
    .join('');
  return btoa(binaryString);
}

export function safeBase64Decode(base64: string): string {
  // Decode base64 to binary string then to UTF-8
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return new TextDecoder().decode(bytes);
}
