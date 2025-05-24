class CleanupExpiredPayloadsJob < ApplicationJob
  queue_as :default

  def perform
    # Clean up expired payloads and their associated files
    expired_payloads = EncryptedPayload.includes(:encrypted_files)
                                     .where("expires_at < ? OR remaining_views <= 0", Time.current)

    deleted_files_count = 0
    deleted_payloads_count = 0

    expired_payloads.find_each do |payload|
      deleted_files_count += payload.encrypted_files.count
      payload.destroy
      deleted_payloads_count += 1
    end

    Rails.logger.info "Cleanup completed: removed #{deleted_payloads_count} expired payloads and #{deleted_files_count} associated files"

    # Clean up orphaned files using a more robust approach
    begin
      # Find files that don't have a corresponding payload
      orphaned_count = EncryptedFile.where.not(
        encrypted_payload_id: EncryptedPayload.select(:id)
      ).delete_all

      if orphaned_count > 0
        Rails.logger.info "Cleaned up #{orphaned_count} orphaned files"
      end
    rescue StandardError => e
      Rails.logger.warn "Could not clean orphaned files: #{e.message}"
      # Continue execution even if orphaned file cleanup fails
    end
  end
end
