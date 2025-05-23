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

    # Also clean up any orphaned files (shouldn't happen, but just in case)
    orphaned_files = EncryptedFile.left_joins(:encrypted_payload).where(encrypted_payloads: { id: nil })
    orphaned_count = orphaned_files.count
    orphaned_files.delete_all

    if orphaned_count > 0
      Rails.logger.info "Cleaned up #{orphaned_count} orphaned files"
    end
  end
end
