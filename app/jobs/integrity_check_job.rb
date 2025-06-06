class IntegrityCheckJob < ApplicationJob
  queue_as :low_priority

  def perform
    corrupted_payloads = []
    corrupted_files = []

    EncryptedPayload.find_in_batches(batch_size: 100) do |batch|
      batch.each do |payload|
        unless payload.send(:verify_integrity)
          corrupted_payloads << payload.id

          AuditService.log(
            event_type: "integrity_check_failed",
            payload_id: payload.id,
            severity: "critical",
            metadata: {
              checksum_mismatch: true,
              expected_checksum: payload.ciphertext_checksum,
              actual_checksum: Digest::SHA256.hexdigest(payload.ciphertext)
            }
          )
        end
      end
    end

    EncryptedFile.includes(:encrypted_payload).find_in_batches(batch_size: 100) do |batch|
      batch.each do |file|
        unless file.send(:verify_integrity)
          corrupted_files << file.id
        end
      end
    end

    if corrupted_payloads.any? || corrupted_files.any?
      SecurityAlertService.send_alert(
        severity: "critical",
        title: "Data Integrity Check Failed",
        details: "Found #{corrupted_payloads.count} corrupted payloads and #{corrupted_files.count} corrupted files",
        metadata: {
          corrupted_payload_ids: corrupted_payloads,
          corrupted_file_ids: corrupted_files
        }
      )
    end

    Rails.logger.info "Integrity check completed: #{corrupted_payloads.count} corrupted payloads, #{corrupted_files.count} corrupted files"
  end
end
