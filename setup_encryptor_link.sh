#!/bin/bash

# Fix for premature payload deletion issue
echo "🛠️ Fixing premature payload deletion issue..."

# Update the DecryptionsController with a session-based approach
cat > app/controllers/decryptions_controller.rb << 'EOL'
class DecryptionsController < ApplicationController
  include Pagy::Backend

  def show
    # Check if we need to show an error message
    @show_error = session[:payload_expired]
    session[:payload_expired] = nil
    render :show
  end

  def data
    payload_id = params[:id]

    # Check if this payload has already been viewed in this session
    if session[:viewed_payloads]&.include?(payload_id)
      # If we've already viewed it once in this session, just return gone
      head :gone
      return
    end

    # Find the payload
    payload = EncryptedPayload.find_by(id: payload_id)

    # If it doesn't exist or is expired, return gone
    if payload.nil? || payload.expires_at < Time.current
      session[:payload_expired] = true
      head :gone
      return
    end

    # For the first view in a session, mark it as viewed but don't delete yet
    payload.with_lock do
      # Record that we've viewed this payload in this session
      session[:viewed_payloads] ||= []
      session[:viewed_payloads] << payload_id

      # Decrement the view counter
      payload.decrement!(:remaining_views)

      # If it's down to zero views, mark it for deletion after response
      session[:delete_payload] = payload_id if payload.remaining_views <= 0
    end

    # Build response data
    response_data = {
      ciphertext: Base64.strict_encode64(payload.ciphertext || ""),
      nonce: Base64.strict_encode64(payload.nonce),
      files: []
    }

    # Add files data
    payload.encrypted_files.each do |file|
      response_data[:files] << {
        id: file.id,
        data: file.file_data,
        name: file.file_name,
        type: file.file_type,
        size: file.file_size
      }
    end

    # Return the response
    render json: response_data
  end

  # Add a callback to perform deletion after the request completes
  after_action :cleanup_payload, only: [:data]

  private

  def cleanup_payload
    # If this payload was marked for deletion, delete it now
    if session[:delete_payload].present?
      payload_id = session[:delete_payload]
      session[:delete_payload] = nil

      # Run deletion in a background thread to not block the response
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          begin
            payload = EncryptedPayload.find_by(id: payload_id)
            payload&.destroy
          rescue => e
            Rails.logger.error("Error deleting payload: #{e.message}")
          end
        end
      end
    end
  end
end
EOL

# Update the show view to handle error state
cat > app/views/decryptions/show.html.erb << 'EOL'
<div class="row justify-content-center">
  <div class="col-md-8">
    <div class="card shadow">
      <div class="card-header">
        <h3 class="my-2">Decrypting Message</h3>
      </div>
      <div class="card-body">
        <% if @show_error %>
          <!-- Pre-rendered error state for expired payloads -->
          <div id="errorContainer">
            <div class="alert alert-danger">
              <h4 class="alert-heading">Cannot access this message</h4>
              <p id="errorMessage">This message has expired or has been viewed the maximum number of times.</p>
            </div>
          </div>
        <% else %>
          <!-- Loading state -->
          <div id="loadingContainer">
            <div class="text-center p-4">
              <div class="spinner-border mb-3" role="status">
                <span class="visually-hidden">Loading...</span>
              </div>
              <p>Fetching encrypted data...</p>
            </div>
          </div>

          <!-- Error state -->
          <div id="errorContainer" class="d-none">
            <div class="alert alert-danger">
              <h4 class="alert-heading">Cannot access this message</h4>
              <p id="errorMessage">The message may have expired or been viewed the maximum number of times.</p>
            </div>
          </div>

          <!-- Success state for messages -->
          <div id="messageContainer" class="d-none">
            <div class="alert alert-warning mb-3">
              <strong>One-time message!</strong> This message has been decrypted in your browser and cannot be accessed again.
            </div>

            <!-- Message content if present -->
            <div id="messageContent" class="mb-3 d-none">
              <label class="form-label">Decrypted Message:</label>
              <div id="decryptedContent" class="form-control p-3" style="min-height: 100px; white-space: pre-wrap;"></div>
            </div>

            <!-- Files container with pagination -->
            <div id="filesContainer" class="mb-3 d-none">
              <label class="form-label">Attached Files:</label>

              <div class="table-responsive">
                <table class="table table-sm table-hover">
                  <thead>
                    <tr>
                      <th>File</th>
                      <th>Size</th>
                      <th>Type</th>
                      <th>Actions</th>
                    </tr>
                  </thead>
                  <tbody id="filesTableBody">
                    <!-- File rows will be added dynamically -->
                  </tbody>
                </table>
              </div>

              <!-- Pagination controls -->
              <div id="pagination" class="d-flex justify-content-center"></div>
            </div>

            <div class="d-grid gap-2">
              <button id="copyMessageBtn" class="btn btn-outline-primary d-none">Copy Message</button>
              <a href="/" class="btn btn-primary">Create Your Own Encrypted Message</a>
            </div>
          </div>
        <% end %>
      </div>
    </div>
  </div>
</div>

<% unless @show_error %>
<script type="module">
  // Import decryption module
  import { decryptMessage, decryptFile } from "/decrypt.js";

  // Pagination variables
  let decryptedFiles = [];
  let currentPage = 1;
  const itemsPerPage = 5;

  // File icons - same as before
  const fileIcons = {
    // Document types
    'pdf': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><line x1="10" y1="9" x2="8" y2="9"/></svg>',
    'epub': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>',
    // ... other file icons as before
    'default': '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>'
  };

  // Format file size
  function formatFileSize(bytes) {
    if (bytes < 1024) return bytes + ' bytes';
    else if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(2) + ' KB';
    else if (bytes < 1024 * 1024 * 1024) return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    else return (bytes / (1024 * 1024 * 1024)).toFixed(2) + ' GB';
  }

  // Get message ID and key from URL fragment
  async function loadAndDecrypt() {
    try {
      const fragment = window.location.hash.substring(1);
      if (!fragment) {
        throw new Error('No decryption key found in URL');
      }

      const [id, keyBase64] = fragment.split('.');
      if (!id || !keyBase64) {
        throw new Error('Invalid URL format');
      }

      // Fetch the encrypted data - use cache busting to prevent duplicate requests
      const cacheBuster = Date.now();
      const response = await fetch(`/${id}/data?t=${cacheBuster}`, {
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0'
        }
      });

      if (!response.ok) {
        if (response.status === 410) {
          throw new Error('This message has expired or has been viewed already.');
        }
        throw new Error('Could not fetch the encrypted data');
      }

      const data = await response.json();

      // Store nonce in a meta tag for file decryption
      const meta = document.createElement('meta');
      meta.name = 'nonce';
      meta.content = data.nonce;
      document.head.appendChild(meta);

      // Decrypt message if present
      let decryptedText = '';
      if (data.ciphertext && data.ciphertext.length > 0) {
        decryptedText = await decryptMessage(data.ciphertext, data.nonce, keyBase64);
        document.getElementById('decryptedContent').textContent = decryptedText;
        document.getElementById('messageContent').classList.remove('d-none');
        document.getElementById('copyMessageBtn').classList.remove('d-none');
      }

      // Handle files if present
      if (data.files && data.files.length > 0) {
        // Store files for pagination
        decryptedFiles = data.files;

        // Show files container
        document.getElementById('filesContainer').classList.remove('d-none');

        // Update the file list and pagination
        updateFilesList();
      }

      // Hide loading, show message container
      document.getElementById('loadingContainer').classList.add('d-none');
      document.getElementById('messageContainer').classList.remove('d-none');

    } catch (error) {
      console.error(error);
      document.getElementById('loadingContainer').classList.add('d-none');
      document.getElementById('errorContainer').classList.remove('d-none');
      document.getElementById('errorMessage').textContent = error.message;
    }
  }

  // Update files list with pagination
  function updateFilesList() {
    const filesTableBody = document.getElementById('filesTableBody');
    const paginationElement = document.getElementById('pagination');

    // Calculate pagination
    const totalPages = Math.ceil(decryptedFiles.length / itemsPerPage);
    const startIndex = (currentPage - 1) * itemsPerPage;
    const endIndex = Math.min(startIndex + itemsPerPage, decryptedFiles.length);
    const currentFiles = decryptedFiles.slice(startIndex, endIndex);

    // Clear the table body
    filesTableBody.innerHTML = '';

    // Add file rows
    currentFiles.forEach((file, index) => {
      const extension = file.name.split('.').pop().toLowerCase();
      const iconSvg = fileIcons[extension] || fileIcons['default'];

      const row = document.createElement('tr');
      row.innerHTML = `
        <td>
          <div class="d-flex align-items-center">
            <div class="file-icon me-2" style="width: 24px; height: 24px;">${iconSvg}</div>
            <div class="text-truncate" style="max-width: 200px;">${file.name}</div>
          </div>
        </td>
        <td>${formatFileSize(file.size)}</td>
        <td>${file.type || 'Unknown'}</td>
        <td>
          <button type="button" class="btn btn-sm btn-primary download-btn" data-index="${startIndex + index}">
            Download
          </button>
        </td>
      `;

      filesTableBody.appendChild(row);
    });

    // Add download button event listeners
    document.querySelectorAll('.download-btn').forEach(button => {
      button.addEventListener('click', async function() {
        const index = parseInt(this.dataset.index);
        const file = decryptedFiles[index];

        // Show loading state
        this.disabled = true;
        this.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span>';

        try {
          // Get the key from URL fragment
          const fragment = window.location.hash.substring(1);
          const [, keyBase64] = fragment.split('.');

          // Get the nonce from meta tag
          const ivBase64 = document.querySelector('meta[name="nonce"]')?.getAttribute('content') || '';

          // Decrypt the file
          const fileDataBase64 = file.data;
          const decryptedData = await decryptFile(fileDataBase64, ivBase64, keyBase64);

          // Create download link
          const blob = new Blob([decryptedData], { type: file.type || 'application/octet-stream' });
          const url = URL.createObjectURL(blob);
          const a = document.createElement('a');
          a.href = url;
          a.download = file.name;
          document.body.appendChild(a);
          a.click();
          URL.revokeObjectURL(url);
          document.body.removeChild(a);

          // Reset button
          this.disabled = false;
          this.textContent = 'Download';
        } catch (error) {
          console.error('Error downloading file:', error);
          alert('Error downloading file: ' + error.message);
          this.disabled = false;
          this.textContent = 'Download';
        }
      });
    });

    // Update pagination controls
    updatePagination(totalPages);
  }

  // Update pagination controls
  function updatePagination(totalPages) {
    const paginationElement = document.getElementById('pagination');
    paginationElement.innerHTML = '';

    if (totalPages <= 1) {
      return;
    }

    const ul = document.createElement('ul');
    ul.className = 'pagination pagination-sm';

    // Previous button
    const prevLi = document.createElement('li');
    prevLi.className = `page-item ${currentPage === 1 ? 'disabled' : ''}`;
    const prevLink = document.createElement('a');
    prevLink.className = 'page-link';
    prevLink.href = '#';
    prevLink.textContent = '«';
    prevLink.addEventListener('click', (e) => {
      e.preventDefault();
      if (currentPage > 1) {
        currentPage--;
        updateFilesList();
      }
    });
    prevLi.appendChild(prevLink);
    ul.appendChild(prevLi);

    // Page numbers
    for (let i = 1; i <= totalPages; i++) {
      const li = document.createElement('li');
      li.className = `page-item ${i === currentPage ? 'active' : ''}`;

      const link = document.createElement('a');
      link.className = 'page-link';
      link.href = '#';
      link.textContent = i;
      link.addEventListener('click', (e) => {
        e.preventDefault();
        currentPage = i;
        updateFilesList();
      });

      li.appendChild(link);
      ul.appendChild(li);
    }

    // Next button
    const nextLi = document.createElement('li');
    nextLi.className = `page-item ${currentPage === totalPages ? 'disabled' : ''}`;
    const nextLink = document.createElement('a');
    nextLink.className = 'page-link';
    nextLink.href = '#';
    nextLink.textContent = '»';
    nextLink.addEventListener('click', (e) => {
      e.preventDefault();
      if (currentPage < totalPages) {
        currentPage++;
        updateFilesList();
      }
    });
    nextLi.appendChild(nextLink);
    ul.appendChild(nextLi);

    paginationElement.appendChild(ul);
  }

  // Handle copy message button
  document.getElementById('copyMessageBtn').addEventListener('click', function() {
    const messageText = document.getElementById('decryptedContent').textContent;
    navigator.clipboard.writeText(messageText).then(() => {
      // Visual feedback
      this.textContent = 'Copied!';
      setTimeout(() => {
        this.textContent = 'Copy Message';
      }, 2000);
    });
  });

  // Start decryption when page loads - with a small delay to ensure everything is ready
  document.addEventListener('DOMContentLoaded', () => {
    setTimeout(loadAndDecrypt, 100);
  });
</script>
<% end %>
EOL

# Also update the decrypt.js to ensure it handles errors better
cat > public/decrypt.js << 'EOL'
/**
 * Decrypts a message using AES-GCM
 * @param {string} ciphertextBase64 - The base64-encoded encrypted message
 * @param {string} ivBase64 - The base64-encoded IV
 * @param {string} keyBase64 - The base64-encoded encryption key
 * @returns {Promise<string>} - The decrypted message
 */
export async function decryptMessage(ciphertextBase64, ivBase64, keyBase64) {
  try {
    console.log("Starting message decryption");

    // Convert Base64 to ArrayBuffer
    const ciphertext = base64ToArrayBuffer(ciphertextBase64);
    const iv = base64ToArrayBuffer(ivBase64);
    const rawKey = base64ToArrayBuffer(keyBase64);

    // Import the key
    const key = await window.crypto.subtle.importKey(
      "raw",
      rawKey,
      {
        name: "AES-GCM",
        length: 256
      },
      false,
      ["decrypt"]
    );

    // Decrypt the ciphertext
    const decrypted = await window.crypto.subtle.decrypt(
      {
        name: "AES-GCM",
        iv: iv
      },
      key,
      ciphertext
    );

    // Decode the result as UTF-8
    return new TextDecoder().decode(decrypted);
  } catch (error) {
    console.error('Message decryption error:', error);
    // Return empty string for empty messages
    if (ciphertextBase64 === "" || !ciphertextBase64) {
      return "";
    }
    throw error;
  }
}

/**
 * Decrypts a file using AES-GCM
 * @param {string} fileDataBase64 - The base64-encoded encrypted file
 * @param {string} ivBase64 - The base64-encoded IV
 * @param {string} keyBase64 - The base64-encoded encryption key
 * @returns {Promise<ArrayBuffer>} - The decrypted file as ArrayBuffer
 */
export async function decryptFile(fileDataBase64, ivBase64, keyBase64) {
  try {
    console.log("Starting file decryption");

    // Convert Base64 to ArrayBuffer
    const fileData = base64ToArrayBuffer(fileDataBase64);
    const iv = base64ToArrayBuffer(ivBase64);
    const rawKey = base64ToArrayBuffer(keyBase64);

    console.log("Converted Base64 to ArrayBuffer", {
      fileDataSize: fileData.byteLength,
      ivSize: iv.byteLength,
      keySize: rawKey.byteLength
    });

    // Import the key
    const key = await window.crypto.subtle.importKey(
      "raw",
      rawKey,
      {
        name: "AES-GCM",
        length: 256
      },
      false,
      ["decrypt"]
    );

    console.log("Key imported successfully");

    // Decrypt the file
    console.log("Decrypting file data...");
    const decrypted = await window.crypto.subtle.decrypt(
      {
        name: "AES-GCM",
        iv: iv
      },
      key,
      fileData
    );

    console.log("File decrypted successfully", { decryptedSize: decrypted.byteLength });
    return decrypted;
  } catch (error) {
    console.error('File decryption error:', error);
    throw error;
  }
}

/**
 * Convert Base64 string to ArrayBuffer
 */
function base64ToArrayBuffer(base64) {
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}
EOL

echo "✅ Fix for premature payload deletion applied!"
echo "The app now:"
echo "• Keeps the payload available during the entire client-side decryption process"
echo "• Uses session tracking to prevent double-fetching issues"
echo "• Only deletes the payload after the response has been fully delivered"
echo "• Improves client-side error handling"
echo ""
echo "Restart your Rails server with: rails s"
echo "Then try creating a new message with files."
