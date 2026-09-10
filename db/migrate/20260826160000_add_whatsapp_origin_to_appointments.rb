class AddWhatsappOriginToAppointments < ActiveRecord::Migration[8.1]
  def up
    add_reference :appointments, :conversation, foreign_key: true
    add_column :appointments, :whatsapp_confirmation_sent_at, :datetime

    # Preserva o vínculo das consultas que a IA já criou antes desta coluna.
    # Escolhe a conversa mais recente do mesmo paciente e organização.
    execute <<~SQL.squish
      UPDATE appointments
      SET conversation_id = (
        SELECT conversations.id
        FROM conversations
        WHERE conversations.organization_id = appointments.organization_id
          AND conversations.patient_id = appointments.patient_id
        ORDER BY conversations.created_at DESC
        LIMIT 1
      )
      FROM users
      WHERE appointments.created_by_id = users.id
        AND users.role = 'ia'
        AND appointments.conversation_id IS NULL
    SQL
  end

  def down
    remove_column :appointments, :whatsapp_confirmation_sent_at
    remove_reference :appointments, :conversation, foreign_key: true
  end
end
