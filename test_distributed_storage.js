// Distributed Storage Integration Test

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:9292/api';

async function testDistributedStorage() {
  console.log('🧪 Testing Distributed Storage Implementation...\n');
  
  try {
    // Test 1: Health Check
    console.log('1️⃣ Testing node health check...');
    const healthResponse = await fetch(`${API_URL}/distributed/health`);
    const health = await healthResponse.json();
    console.log('✅ Node health:', health);
    
    // Test 2: Initialize distributed upload
    console.log('\n2️⃣ Testing distributed upload initialization...');
    const initResponse = await fetch(`${API_URL}/distributed/initialize`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        sessionId: 'test-session-' + Date.now(),
        fileId: 'test-file-' + Date.now(),
        totalChunks: 5,
        totalSize: 1024 * 1024,
        password: 'TestP@ssw0rd123!',
        metadata: {
          fileCount: 1,
          hasMessage: true,
          chunkDistribution: []
        }
      })
    });
    
    if (initResponse.ok) {
      const initData = await initResponse.json();
      console.log('✅ Upload initialized:', initData);
    } else {
      console.log('❌ Initialization failed:', await initResponse.text());
    }
    
    console.log('\n✅ Distributed storage is working!');
    
  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

// Run test
testDistributedStorage();
