# Streaming Upload Debugging Guide

## Enable Debug Mode

### Frontend Debugging
1. Open browser console
2. Run: `localStorage.setItem('debug_streaming', 'true')`
3. Reload the page
4. All streaming operations will be logged with timestamps

### Backend Debugging
1. Set environment variable: `export RACK_ENV=development`
2. Logs will be in `backend/logs/app.log`
3. Watch logs: `tail -f backend/logs/app.log`

## Test Commands

### Quick Test
```bash
# Test streaming endpoint health
curl http://localhost:9292/api/streaming/health
```

### Backend Test
```bash
npm run backend:test
```

## Common Issues

### 1. "Failed to initialize upload"
- Check backend is running: `curl http://localhost:9292/api/status`
- Verify password meets requirements (8+ chars, upper, lower, number, special)
- Check backend logs for specific error

### 2. "Chunk upload failed"
- Enable debug mode and check console logs
- Verify chunk size (should be 1MB)
- Check network tab for response details
- Backend logs will show chunk processing details

### 3. "Finalization failed"
- Usually means missing chunks
- Check backend logs for which chunks are missing
- Verify all chunks were uploaded successfully

### 4. Memory issues
- Chunks are processed one at a time
- Browser should handle files up to 4GB without issues
- Check browser console for memory warnings

## Backend Endpoints

- `POST /api/streaming/initialize` - Start upload session
- `POST /api/streaming/chunk` - Upload a chunk (multipart)
- `POST /api/streaming/finalize` - Complete upload
- `GET /api/streaming/info/:id` - Get file info
- `POST /api/streaming/download/:id/chunk/:index` - Download chunk
- `GET /api/streaming/health` - Health check

## Monitoring Upload Progress

1. Frontend console will show:
   - `[Upload] Starting upload for filename`
   - `[Upload] Session initialized: {sessionId, fileId}`
   - `[Upload] Queueing chunk X/Y`
   - `[Upload] Progress: XX.X%`
   - `[Upload] Upload completed successfully`

2. Backend logs will show:
   - Session creation
   - Each chunk received with size and hash
   - Finalization process
   - Any errors with stack traces

## Performance Tips

1. **Concurrent uploads**: Limited to 3 chunks at once
2. **Chunk size**: 1MB is optimal for most connections
3. **Retry logic**: Failed chunks retry up to 3 times with exponential backoff
4. **Memory usage**: Each chunk uses ~2MB RAM (1MB original + encrypted)

## Testing Large Files

```bash
# Create a test file
dd if=/dev/urandom of=test-100mb.bin bs=1M count=100

# Upload via curl (requires the test script to be adapted)
# Or use the web interface with debug mode enabled
```
