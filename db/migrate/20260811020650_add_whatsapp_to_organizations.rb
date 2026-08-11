class AddWhatsappToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :whatsapp_number, :string
    add_column :organizations, :whatsapp_session_id, :string
    add_column :organizations, :ai_enabled, :boolean, default: false, null: false

    add_index :organizations, :whatsapp_number, unique: true
  end
end
