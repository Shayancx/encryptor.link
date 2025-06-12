namespace :data do
  desc "Migrate existing file data to Active Storage and fix any issues"
  task fix_files: :environment do
    puts "Starting file data migration and fixes..."
    
    fixed_count = 0
    error_count = 0
    
    EncryptedFile.find_each do |file|
      begin
        # Skip if already using Active Storage properly
        if file.encrypted_blob.attached?
          puts "✓ File #{file.id} already migrated"
          next
        end
        
        # If file_data exists, migrate it
        if file.respond_to?(:file_data) && file.file_data.present?
          puts "Migrating file #{file.id} (#{file.file_name})..."
          file.store_encrypted_data(file.file_data)
          file.save!
          fixed_count += 1
          puts "✓ Migrated file #{file.id}"
        else
          puts "⚠ File #{file.id} has no data to migrate"
        end
      rescue => e
        error_count += 1
        puts "✗ Error migrating file #{file.id}: #{e.message}"
      end
    end
    
    puts "\n" + "="*50
    puts "Migration complete!"
    puts "Files fixed: #{fixed_count}"
    puts "Errors: #{error_count}"
    puts "="*50
  end
  
  desc "Clean up orphaned encrypted files"
  task cleanup_orphaned_files: :environment do
    puts "Looking for orphaned files..."
    
    orphaned = EncryptedFile.includes(:encrypted_payload).where(encrypted_payloads: { id: nil })
    count = orphaned.count
    
    if count > 0
      puts "Found #{count} orphaned files"
      orphaned.destroy_all
      puts "✓ Cleaned up #{count} orphaned files"
    else
      puts "✓ No orphaned files found"
    end
  end
end
