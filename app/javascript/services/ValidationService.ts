interface ValidationInput {
  message?: string;
  files?: File[];
  ttl?: number;
  views?: number;
  password?: string;
}

export class ValidationService {
  static validate(input: ValidationInput): string | null {
    const { message = '', files = [], ttl = 0, views = 0 } = input;

    // Check if either message or files are provided
    if (!message.trim() && files.length === 0) {
      return 'Please enter a message or select at least one file';
    }

    // Validate TTL
    if (ttl <= 0) {
      return 'Invalid expiration time';
    }

    if (ttl > 7 * 24 * 60 * 60) { // 7 days in seconds
      return 'Expiration time cannot exceed 7 days';
    }

    // Validate views
    if (views <= 0) {
      return 'Invalid view limit';
    }

    if (views > 5) {
      return 'View limit cannot exceed 5';
    }

    // Validate files
    if (files.length > 0) {
      const maxFileSize = 1000 * 1024 * 1024; // 1000MB
      const totalSize = files.reduce((sum, file) => sum + file.size, 0);
      
      if (totalSize > maxFileSize) {
        return `Total file size cannot exceed 1000MB. Current: ${(totalSize / (1024 * 1024)).toFixed(2)}MB`;
      }

      for (const file of files) {
        if (file.size === 0) {
          return `File "${file.name}" is empty`;
        }
      }
    }

    return null;
  }

  static validatePassword(password: string): string | null {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    return null;
  }

  static sanitizeInput(input: string): string {
    // Basic XSS prevention
    return input
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#x27;')
      .replace(/\//g, '&#x2F;');
  }
}

export default ValidationService;
