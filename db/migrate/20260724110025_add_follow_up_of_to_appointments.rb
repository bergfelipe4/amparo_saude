class AddFollowUpOfToAppointments < ActiveRecord::Migration[8.1]
  def change
    add_reference :appointments, :follow_up_of, null: true, foreign_key: { to_table: :appointments }
  end
end
