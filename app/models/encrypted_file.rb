class EncryptedFile < ApplicationRecord
  belongs_to :message, optional: true
  belongs_to :encrypted_payload, optional: true
  
  validates :file_data, presence: true
  validates :file_name, presence: true
  validates :file_size, presence: true
  
  # Rails 8 compatible serialization
  serialize :metadata, coder: JSON
end
