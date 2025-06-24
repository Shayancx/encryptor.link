/**
 * Utility to handle decryption of combined payloads
 */

import { safeBase64Decode } from './base64-utils'

export function parseCombinedPayload(encodedData: string): any {
  try {
    // First try direct JSON parse (for old format)
    return JSON.parse(atob(encodedData))
  } catch {
    // Try safe decode for new format
    try {
      const decoded = safeBase64Decode(encodedData)
      return JSON.parse(decoded)
    } catch (error) {
      console.error('Failed to parse payload:', error)
      throw new Error('Invalid encrypted data format')
    }
  }
}
