class AddConnectionFieldsToOrganizations < ActiveRecord::Migration[8.1]
  def change
    # whatsapp_token equivale a controlar o WhatsApp real da clínica — sensível
    # como uma senha. Não criptografado ainda (Active Record Encryption não
    # está configurado neste projeto); ver Organization para o alerta.
    add_column :organizations, :whatsapp_token, :string
    add_column :organizations, :whatsapp_connection_status, :string, default: "nao_iniciado", null: false
  end
end
