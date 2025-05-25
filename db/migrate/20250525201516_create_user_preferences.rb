class CreateUserPreferences < ActiveRecord::Migration[8.0]
  def change
    create_table :user_preferences, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :default_ttl
      t.integer :default_views
      t.string :theme_preference
      t.text :encrypted_settings

      t.timestamps
    end
  end
end
