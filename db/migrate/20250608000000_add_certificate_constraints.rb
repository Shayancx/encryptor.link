class AddCertificateConstraints < ActiveRecord::Migration[8.0]
  def change
    add_index :destruction_certificates, :certificate_id, unique: true unless index_exists?(:destruction_certificates, :certificate_id)
    add_index :destruction_certificates, :certificate_hash, unique: true unless index_exists?(:destruction_certificates, :certificate_hash)

    if connection.adapter_name.downcase.include?('postgresql')
      execute <<-SQL
        ALTER TABLE destruction_certificates#{' '}
        ADD CONSTRAINT check_certificate_data_not_empty#{' '}
        CHECK (LENGTH(certificate_data) > 0);
      SQL
    end
  end
end
