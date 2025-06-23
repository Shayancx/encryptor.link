// Test script for streaming upload
// Run with: node test-streaming-upload.js

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

// Configuration
const API_URL = process.env.API_URL || 'http://localhost:9292/api';
const TEST_FILE_SIZE = 5 * 1024 * 1024; // 5MB test file
const CHUNK_SIZE = 1024 * 1024; // 1MB chunks
const PASSWORD = 'TestP@ssw0rd123!';

// Generate test file
function generateTestFile(size) {
  console.log(`Generating ${size / 1024 / 1024}MB test file...`);
  const buffer = crypto.randomBytes(size);
  const filename = `test-${Date.now()}.bin`;
  fs.writeFileSync(filename, buffer);
  console.log(`✓ Generated: ${filename}`);
  return filename;
}

// Test streaming upload
async function testStreamingUpload() {
  const filename = generateTestFile(TEST_FILE_SIZE);
  
  try {
    console.log('\n🧪 Testing Streaming Upload...');
    console.log('================================');
    
    // Step 1: Initialize session
    console.log('\n1. Initializing session...');
    const initResponse = await fetch(`${API_URL}/streaming/initialize`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        filename,
        fileSize: TEST_FILE_SIZE,
        mimeType: 'application/octet-stream',
        password: PASSWORD,
        totalChunks: Math.ceil(TEST_FILE_SIZE / CHUNK_SIZE),
        chunkSize: CHUNK_SIZE
      })
    });
    
    if (!initResponse.ok) {
      throw new Error(`Initialize failed: ${await initResponse.text()}`);
    }
    
    const session = await initResponse.json();
    console.log(`✓ Session created: ${session.session_id}`);
    console.log(`  File ID: ${session.file_id}`);
    
    // Step 2: Upload chunks
    console.log('\n2. Uploading chunks...');
    const fileBuffer = fs.readFileSync(filename);
    const totalChunks = Math.ceil(TEST_FILE_SIZE / CHUNK_SIZE);
    
    for (let i = 0; i < totalChunks; i++) {
      const start = i * CHUNK_SIZE;
      const end = Math.min(start + CHUNK_SIZE, TEST_FILE_SIZE);
      const chunk = fileBuffer.slice(start, end);
      
      // Create form data
      const FormData = require('form-data');
      const formData = new FormData();
      formData.append('session_id', session.session_id);
      formData.append('chunk_index', i.toString());
      formData.append('iv', Buffer.from(crypto.randomBytes(12)).toString('base64'));
      formData.append('chunk_data', chunk, `chunk_${i}`);
      
      const chunkResponse = await fetch(`${API_URL}/streaming/chunk`, {
        method: 'POST',
        body: formData
      });
      
      if (!chunkResponse.ok) {
        throw new Error(`Chunk ${i} upload failed: ${await chunkResponse.text()}`);
      }
      
      const result = await chunkResponse.json();
      console.log(`✓ Chunk ${i + 1}/${totalChunks} uploaded (${result.chunks_received}/${result.total_chunks})`);
    }
    
    // Step 3: Finalize
    console.log('\n3. Finalizing upload...');
    const salt = Buffer.from(crypto.randomBytes(32)).toString('base64');
    const finalizeResponse = await fetch(`${API_URL}/streaming/finalize`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        session_id: session.session_id,
        salt: salt
      })
    });
    
    if (!finalizeResponse.ok) {
      throw new Error(`Finalize failed: ${await finalizeResponse.text()}`);
    }
    
    const finalResult = await finalizeResponse.json();
    console.log(`✓ Upload completed!`);
    console.log(`  File ID: ${finalResult.file_id}`);
    console.log(`  Share URL: ${finalResult.share_url}`);
    
    console.log('\n✅ All tests passed!');
    
  } catch (error) {
    console.error('\n❌ Test failed:', error.message);
  } finally {
    // Clean up test file
    fs.unlinkSync(filename);
    console.log('\n🧹 Cleaned up test file');
  }
}

// Check if fetch is available (Node 18+)
if (typeof fetch === 'undefined') {
  console.error('This script requires Node.js 18+ or install node-fetch');
  process.exit(1);
}

// Run test
testStreamingUpload();
