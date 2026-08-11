class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :patient, foreign_key: true
      t.string :phone_number, null: false
      t.string :status, default: "aberta", null: false
      t.jsonb :context, default: {}, null: false
      t.datetime :last_message_at

      t.timestamps
    end

    add_index :conversations, [:organization_id, :phone_number]
  end
end
