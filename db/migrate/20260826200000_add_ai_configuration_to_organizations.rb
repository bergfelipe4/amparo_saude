class AddAiConfigurationToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :ai_model, :string, null: false, default: "gpt_4o_mini"
    add_column :organizations, :ai_instructions, :text
    add_column :organizations, :ai_phone_policy, :string, null: false, default: "all"
    add_column :organizations, :ai_phone_numbers, :text, array: true, null: false, default: []
  end
end
