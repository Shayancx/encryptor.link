# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:encrypted_files) do
      add_column :is_chunked, TrueClass, default: false
      add_index :is_chunked
    end
  end
end
