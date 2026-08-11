class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.string :role, null: false
      t.text :content
      t.jsonb :tool_calls
      t.jsonb :tool_result
      t.string :whatsapp_message_id

      t.datetime :created_at, null: false
    end

    add_index :messages, :whatsapp_message_id
  end
end
