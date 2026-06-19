class CreateShareTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :share_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token, null: false
      t.jsonb :snapshot_data, null: false, default: {}
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :share_tokens, :token, unique: true
  end
end
