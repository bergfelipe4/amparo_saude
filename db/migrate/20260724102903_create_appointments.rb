class CreateAppointments < ActiveRecord::Migration[8.1]
  def change
    create_table :appointments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.references :professional, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.string :appointment_type, null: false
      t.string :status, null: false, default: "aguardando"

      t.timestamps
    end
    add_index :appointments, [:unit_id, :starts_at]
  end
end
