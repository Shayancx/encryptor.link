# Encryption System Update

## Changes Made

1. **Combined Encryption**: Messages and files are now encrypted together into a single payload
2. **Single Link**: Only one shareable link is generated for the entire encrypted package
3. **Preserved Messages**: Messages are no longer lost when files are attached
4. **Improved UX**: Better file management and progress tracking

## Breaking Changes

- The streaming upload component is no longer used directly in the encrypt page
- Large files (>50MB) should use the dedicated large file upload component

## Usage

1. Add a message (optional)
2. Add files (optional) 
3. Enter password
4. Click "Encrypt All"
5. Share the single generated link

Recipients will see both the message and all files when they decrypt.
