namespace :encryptor do
  desc "Remove expired encrypted payloads"
  task cleanup: :environment do
    deleted_count = EncryptedPayload.where('expires_at < ?', Time.current).delete_all
    puts "Removed #{deleted_count} expired encrypted payloads"
  end
end
