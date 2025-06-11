class EncryptedFile < ApplicationRecord
  belongs_to :message
  
  validates :file_data, presence: true
  
  # Rails 8 compatible serialization
  serialize :metadata
end
