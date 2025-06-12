namespace :data do
  desc "Migrate file data from database to Active Storage"
  task migrate_files: :environment do
    puts "Migrating file data to Active Storage..."
    
    EncryptedFile.find_each do |file|
      next unless file.file_data.present?
      next if file.encrypted_blob.attached?
      
      begin
        # Store the data using the new method
        file.store_encrypted_data(file.file_data)
        file.save!
        puts "Migrated file: #{file.file_name}"
      rescue => e
        puts "Error migrating file #{file.id}: #{e.message}"
      end
    end
    
    puts "Migration complete!"
  end
end
