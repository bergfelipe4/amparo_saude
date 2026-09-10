class CreateAiTokenUsages < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_token_usages do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.string :model, null: false
      t.integer :input_tokens, null: false, default: 0
      t.integer :output_tokens, null: false, default: 0
      t.integer :total_tokens, null: false, default: 0
      t.timestamps
    end
  end
end
