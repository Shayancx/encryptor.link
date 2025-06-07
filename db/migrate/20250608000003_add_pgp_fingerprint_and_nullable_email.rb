class AddPgpFingerprintAndNullableEmail < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :pgp_fingerprint, :string
    add_index :accounts, :pgp_fingerprint, unique: true
    change_column_null :accounts, :email, true
    remove_index :accounts, :email
    add_index :accounts, :email, unique: true, where: "email IS NOT NULL AND status IN (1,2)"
  end
end
