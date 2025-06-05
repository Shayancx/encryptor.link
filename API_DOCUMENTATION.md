# Encryptor.link API Documentation

## Endpoints

### POST /encrypt
Creates an encrypted payload.

**Request Body:**
```json
{
  "ciphertext": "base64_encoded_encrypted_data",
  "nonce": "base64_encoded_nonce",
  "ttl": 3600,
  "views": 1,
  "password_protected": false,
  "password_salt": "base64_encoded_salt",
  "files": [
    {
      "data": "base64_encoded_file_data",
      "name": "filename.txt",
      "type": "text/plain",
      "size": 1024
    }
  ]
}
```

**Response:**
```json
{
  "id": "uuid",
  "password_protected": false
}
```

### GET /:id/data
Retrieves encrypted payload data.

**Response:**
```json
{
  "ciphertext": "base64_encoded_data",
  "nonce": "base64_encoded_nonce",
  "password_protected": false,
  "password_salt": "base64_encoded_salt",
  "files": [
    {
      "id": "uuid",
      "data": "base64_encoded_data",
      "name": "filename.txt",
      "type": "text/plain",
      "size": 1024
    }
  ]
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2025-01-01T00:00:00Z",
  "checks": {
    "database": true,
    "disk_space": true,
    "app_version": "unknown"
  }
}
```

## Rate Limiting

- POST /encrypt: 10 requests per minute per IP
- GET /:id/data: 30 requests per minute per IP
- Payload enumeration protection: 40 unique payloads per 15 minutes per IP

## Error Responses

All endpoints may return the following error responses:

- `400 Bad Request`: Invalid parameters
- `404 Not Found`: Resource not found
- `410 Gone`: Resource expired or no views remaining
- `422 Unprocessable Entity`: Validation errors
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

Error response format:
```json
{
  "error": "Error message"
}
```
