#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

API_URL="${API_URL:-http://localhost:9292/api}"

echo -e "${GREEN}🧪 Streaming Upload Test Suite${NC}"
echo "=============================="

# Test 1: Health Check
echo -e "\n${YELLOW}Test 1: Health Check${NC}"
HEALTH=$(curl -s "$API_URL/streaming/health")
if echo "$HEALTH" | grep -q '"status":"healthy"'; then
    echo -e "${GREEN}✓ Streaming service is healthy${NC}"
else
    echo -e "${RED}✗ Streaming service is unhealthy${NC}"
    echo "$HEALTH"
    exit 1
fi

# Test 2: Initialize with invalid password
echo -e "\n${YELLOW}Test 2: Password Validation${NC}"
INIT_RESPONSE=$(curl -s -X POST "$API_URL/streaming/initialize" \
    -H "Content-Type: application/json" \
    -d '{
        "filename": "test.txt",
        "fileSize": 1000,
        "mimeType": "text/plain",
        "password": "weak",
        "totalChunks": 1,
        "chunkSize": 1000
    }')

if echo "$INIT_RESPONSE" | grep -q "error"; then
    echo -e "${GREEN}✓ Weak password correctly rejected${NC}"
else
    echo -e "${RED}✗ Password validation failed${NC}"
fi

# Test 3: File size limits
echo -e "\n${YELLOW}Test 3: File Size Limits${NC}"
LARGE_FILE_RESPONSE=$(curl -s -X POST "$API_URL/streaming/initialize" \
    -H "Content-Type: application/json" \
    -d '{
        "filename": "huge.bin",
        "fileSize": 209715200,
        "mimeType": "application/octet-stream",
        "password": "TestP@ssw0rd123!",
        "totalChunks": 200,
        "chunkSize": 1048576
    }')

if echo "$LARGE_FILE_RESPONSE" | grep -q "too large"; then
    echo -e "${GREEN}✓ Large file correctly rejected for anonymous user${NC}"
else
    echo -e "${RED}✗ File size limit not enforced${NC}"
fi

# Test 4: Complete upload flow
echo -e "\n${YELLOW}Test 4: Complete Upload Flow${NC}"

# Create test file
TEST_FILE="/tmp/test-streaming-$$"
echo "Hello, streaming upload!" > "$TEST_FILE"

# Initialize
INIT=$(curl -s -X POST "$API_URL/streaming/initialize" \
    -H "Content-Type: application/json" \
    -d '{
        "filename": "small-test.txt",
        "fileSize": 25,
        "mimeType": "text/plain",
        "password": "TestP@ssw0rd123!",
        "totalChunks": 1,
        "chunkSize": 1048576
    }')

SESSION_ID=$(echo "$INIT" | grep -o '"session_id":"[^"]*"' | cut -d'"' -f4)
FILE_ID=$(echo "$INIT" | grep -o '"file_id":"[^"]*"' | cut -d'"' -f4)

if [ -n "$SESSION_ID" ] && [ -n "$FILE_ID" ]; then
    echo -e "${GREEN}✓ Session initialized: $SESSION_ID${NC}"
    
    # Upload chunk
    CHUNK_RESPONSE=$(curl -s -X POST "$API_URL/streaming/chunk" \
        -F "session_id=$SESSION_ID" \
        -F "chunk_index=0" \
        -F "iv=dGVzdGl2MTIzNDU2Nzg5MA==" \
        -F "chunk_data=@$TEST_FILE")
    
    if echo "$CHUNK_RESPONSE" | grep -q '"chunks_received":1'; then
        echo -e "${GREEN}✓ Chunk uploaded successfully${NC}"
        
        # Finalize
        FINALIZE_RESPONSE=$(curl -s -X POST "$API_URL/streaming/finalize" \
            -H "Content-Type: application/json" \
            -d "{
                \"session_id\": \"$SESSION_ID\",
                \"salt\": \"dGVzdHNhbHQxMjM0NTY3ODkwMTIzNDU2Nzg5MDEyMzQ1Njc4OTA=\"
            }")
        
        if echo "$FINALIZE_RESPONSE" | grep -q "$FILE_ID"; then
            echo -e "${GREEN}✓ Upload finalized successfully${NC}"
            echo "  File ID: $FILE_ID"
        else
            echo -e "${RED}✗ Finalization failed${NC}"
            echo "$FINALIZE_RESPONSE"
        fi
    else
        echo -e "${RED}✗ Chunk upload failed${NC}"
        echo "$CHUNK_RESPONSE"
    fi
else
    echo -e "${RED}✗ Session initialization failed${NC}"
    echo "$INIT"
fi

# Cleanup
rm -f "$TEST_FILE"

echo -e "\n${GREEN}✅ Test suite completed${NC}"
