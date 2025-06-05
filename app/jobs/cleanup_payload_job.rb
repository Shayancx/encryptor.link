# frozen_string_literal: true

class CleanupPayloadJob < ApplicationJob
  queue_as :default

  def perform(payload_id)
    payload = EncryptedPayload.find_by(id: payload_id)
    return unless payload && payload.remaining_views <= 0

    Rails.logger.info "Destroying payload #{payload_id} with 0 remaining views"
    payload.destroy
  rescue => e
    Rails.logger.error "Error in cleanup_payload: #{e.message}"
  end
end
