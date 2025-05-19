class CleanupExpiredPayloadsJob < ApplicationJob
  queue_as :default

  def perform
    deleted_count = EncryptedPayload.where("expires_at < ?", Time.current).delete_all
    Rails.logger.info "Removed #{deleted_count} expired encrypted payloads"
  end
end
