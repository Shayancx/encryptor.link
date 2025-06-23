# Read current app.rb
app_content = File.read('app.rb')

# New chunk endpoint with better error handling
new_chunk_endpoint = <<-'RUBY_CODE'
        # Upload chunk - handle multipart form data
        r.post 'chunk' do
          begin
            # Log request details
            LOGGER.info "Chunk upload request received"
            LOGGER.info "Content-Type: #{request.content_type}"
            LOGGER.info "Params: #{request.params.keys.join(', ')}"
            
            # Parse parameters
            session_id = request.params['session_id']
            chunk_index = request.params['chunk_index']
            iv = request.params['iv']
            
            # Validate required parameters
            unless session_id && chunk_index && iv
              response.status = 400
              next { error: "Missing required fields: session_id, chunk_index, or iv" }
            end
            
            # Handle chunk data
            chunk_data = nil
            chunk_file = request.params['chunk_data']
            
            if chunk_file.nil?
              response.status = 400
              next { error: 'Missing chunk_data file' }
            end
            
            # Extract chunk data based on type
            if chunk_file.is_a?(Hash) && chunk_file[:tempfile]
              # Standard Rack::Multipart::UploadedFile
              chunk_data = chunk_file[:tempfile].read
              chunk_file[:tempfile].rewind
              LOGGER.info "Read chunk data from tempfile: #{chunk_data.bytesize} bytes"
            elsif chunk_file.respond_to?(:read)
              # IO-like object
              chunk_data = chunk_file.read
              chunk_file.rewind if chunk_file.respond_to?(:rewind)
              LOGGER.info "Read chunk data from IO: #{chunk_data.bytesize} bytes"
            elsif chunk_file.is_a?(String)
              # Direct string data
              chunk_data = chunk_file
              LOGGER.info "Chunk data is string: #{chunk_data.bytesize} bytes"
            else
              LOGGER.error "Unknown chunk_data type: #{chunk_file.class}"
              response.status = 400
              next { error: "Invalid chunk data format: #{chunk_file.class}" }
            end
            
            # Validate chunk data
            if chunk_data.nil? || chunk_data.empty?
              response.status = 400
              next { error: 'Chunk data is empty' }
            end
            
            # Log chunk details
            LOGGER.info "Processing chunk #{chunk_index} for session #{session_id}"
            LOGGER.info "Chunk size: #{chunk_data.bytesize} bytes"
            LOGGER.info "IV length: #{iv.bytesize} bytes"
            
            # Store chunk
            result = StreamingUpload.store_chunk(
              session_id, 
              chunk_index.to_i, 
              chunk_data, 
              iv
            )
            
            LOGGER.info "Chunk #{chunk_index} stored successfully"
            LOGGER.info "Chunks received: #{result[:chunks_received]}/#{result[:total_chunks]}"
            
            result
          rescue => e
            LOGGER.error "Chunk upload error: #{e.message}"
            LOGGER.error e.backtrace.join("\n")
            response.status = 500
            { error: "Failed to upload chunk: #{e.message}" }
          end
        end
RUBY_CODE

# Replace the chunk endpoint
if app_content.include?('# Upload chunk')
  app_content.gsub!(/# Upload chunk.*?(?=# (?:Finalize|Health check|Get file info))/m, new_chunk_endpoint + "\n        ")
  File.write('app.rb', app_content)
  puts "✓ Updated chunk endpoint in app.rb"
else
  puts "⚠️  Could not find chunk endpoint marker in app.rb"
fi
RUBY_CODE

cd backend && ruby fix_chunk_endpoint.rb && cd ..

# 5. Create comprehensive test suite
echo -e "${YELLOW}Step 5: Creating test suite...${NC}"

cat > test-streaming-fixed.js << 'EOF'
// Comprehensive test for fixed streaming upload
const fs = require('fs');
const crypto = require('crypto');
const FormData = require('form-data');

const API_URL = process.env.API_URL || 'http://localhost:9292/api';
const TEST_SIZES = [
  { name: 'Small', size: 100 * 1024 },           // 100KB
  { name: 'Medium', size: 5 * 1024 * 1024 },     // 5MB
  { name: 'Large', size: 20 * 1024 * 1024 }      // 20MB
];

async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function testStreamingUpload(testSize) {
  console.log(`\n🧪 Testing ${testSize.name} file (${(testSize.size / 1024 / 1024).toFixed(2)}MB)...`);
  
  // Generate test file
  const buffer = crypto.randomBytes(testSize.size);
  const filename = `test-${testSize.name.toLowerCase()}-${Date.now()}.bin`;
  fs.writeFileSync(filename, buffer);
  
  try {
    // Initialize
    console.log('1. Initializing session...');
    const CHUNK_SIZE = 1024 * 1024; // 1MB
    const totalChunks = Math.ceil(testSize.size / CHUNK_SIZE);
    
    const initResponse = await fetch(`${API_URL}/streaming/initialize`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        filename,
        fileSize: testSize.size,
        mimeType: 'application/octet-stream',
        password: 'TestP@ssw0rd123!',
        totalChunks,
        chunkSize: CHUNK_SIZE
      })
    });
    
    if (!initResponse.ok) {
      throw new Error(`Initialize failed: ${await initResponse.text()}`);
    }
    
    const session = await initResponse.json();
    console.log(`✓ Session: ${session.session_id}`);
    
    // Upload chunks
    console.log(`2. Uploading ${totalChunks} chunks...`);
    const startTime = Date.now();
    
    for (let i = 0; i < totalChunks; i++) {
      const start = i * CHUNK_SIZE;
      const end = Math.min(start + CHUNK_SIZE, testSize.size);
      const chunk = buffer.slice(start, end);
      
      const formData = new FormData();
      formData.append('session_id', session.session_id);
      formData.append('chunk_index', i.toString());
      formData.append('iv', Buffer.from(crypto.randomBytes(12)).toString('base64'));
      formData.append('chunk_data', chunk, {
        filename: `chunk_${i}.enc`,
        contentType: 'application/octet-stream'
      });
      
      const chunkResponse = await fetch(`${API_URL}/streaming/chunk`, {
        method: 'POST',
        body: formData,
        headers: formData.getHeaders()
      });
      
      if (!chunkResponse.ok) {
        const error = await chunkResponse.text();
        throw new Error(`Chunk ${i} failed: ${error}`);
      }
      
      const result = await chunkResponse.json();
      process.stdout.write(`\r  Progress: ${result.chunks_received}/${result.total_chunks} chunks`);
    }
    
    console.log('');
    
    // Finalize
    console.log('3. Finalizing...');
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
    const elapsed = ((Date.now() - startTime) / 1000).toFixed(2);
    const speed = ((testSize.size / 1024 / 1024) / elapsed).toFixed(2);
    
    console.log(`✅ Upload completed!`);
    console.log(`  File ID: ${finalResult.file_id}`);
    console.log(`  Time: ${elapsed}s`);
    console.log(`  Speed: ${speed} MB/s`);
    
    return { success: true, fileId: finalResult.file_id };
    
  } catch (error) {
    console.error(`❌ Test failed: ${error.message}`);
    return { success: false, error: error.message };
    
  } finally {
    fs.unlinkSync(filename);
  }
}

async function runAllTests() {
  console.log('🚀 Running Streaming Upload Tests');
  console.log('=================================');
  
  const results = [];
  
  for (const testSize of TEST_SIZES) {
    const result = await testStreamingUpload(testSize);
    results.push({ ...testSize, ...result });
    
    if (!result.success) {
      console.log('\n⚠️  Stopping tests due to failure');
      break;
    }
    
    await sleep(1000); // Pause between tests
  }
  
  // Summary
  console.log('\n📊 Test Summary:');
  console.log('================');
  results.forEach(result => {
    const status = result.success ? '✅' : '❌';
    console.log(`${status} ${result.name}: ${result.success ? 'PASSED' : 'FAILED'}`);
    if (!result.success) {
      console.log(`   Error: ${result.error}`);
    }
  });
}

// Check Node version
if (typeof fetch === 'undefined') {
  console.error('This script requires Node.js 18+ or install node-fetch');
  process.exit(1);
}

runAllTests().catch(console.error);
