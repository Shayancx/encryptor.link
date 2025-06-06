namespace :integrity do
  desc "Calculate checksums for existing payloads"
  task backfill: :environment do
    puts "Calculating checksums for existing payloads..."

    EncryptedPayload.where(ciphertext_checksum: nil).find_each do |payload|
      payload.update_columns(
        ciphertext_checksum: Digest::SHA256.hexdigest(payload.ciphertext),
        nonce_checksum: Digest::SHA256.hexdigest(payload.nonce)
      )
      print "."
    end

    puts "\nCalculating checksums for existing files..."

    EncryptedFile.where(file_data_checksum: nil).find_each do |file|
      file.update_column(
        :file_data_checksum,
        Digest::SHA256.hexdigest(file.file_data)
      )
      print "."
    end

    puts "\nDone!"
  end
end
