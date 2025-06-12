class CleanupExpiredFilesJob < ApplicationJob
  queue_as :default

  def perform
    # Find and delete expired payloads and their files
    expired_payloads = EncryptedPayload
      .where("expires_at < ? OR remaining_views <= 0", Time.current)
      .includes(:encrypted_files)

    expired_payloads.find_each do |payload|
      # Delete attached files from storage
      payload.encrypted_files.each do |file|
        file.encrypted_blob.purge if file.encrypted_blob.attached?
      end
      
      # Delete the payload (cascades to encrypted_files)
      payload.destroy
    end
    
    Rails.logger.info "Cleaned up #{expired_payloads.count} expired payloads"
  end
end
