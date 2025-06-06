class CreateAdminUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_users, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, null: false
      t.boolean :active, default: true
      t.timestamps
    end

    add_index :admin_users, :email, unique: true
    add_index :admin_users, :role
  end
end
