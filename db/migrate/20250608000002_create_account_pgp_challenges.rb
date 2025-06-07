class CreateAccountPgpChallenges < ActiveRecord::Migration[8.0]
  def change
    create_table :account_pgp_challenges, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.string :nonce, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :account_pgp_challenges, :account_id
  end
end
