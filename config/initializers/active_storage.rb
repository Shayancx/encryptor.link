# Ensure ActiveStorage uses secure defaults
Rails.application.config.to_prepare do
  ActiveStorage::Current.url_options = { 
    host: Rails.env.production? ? 'https://encryptor.link' : 'http://localhost:3000' 
  }
end

# Configure ActiveStorage to not analyze files (since they're encrypted)
Rails.application.config.active_storage.variant_processor = :mini_magick
Rails.application.config.active_storage.analyzers = []
Rails.application.config.active_storage.previewers = []
