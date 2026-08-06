class RenameRecepcaoToSecretariaAndAddPermissions < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE users SET role = 'secretaria' WHERE role = 'recepcao'"

    add_reference :appointments, :created_by, foreign_key: { to_table: :users }, null: true

    create_table :appointment_permissions do |t|
      t.references :appointment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :granted_by, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :appointment_permissions, [:appointment_id, :user_id], unique: true, name: "index_appointment_permissions_on_appointment_and_user"
  end

  def down
    remove_index :appointment_permissions, name: "index_appointment_permissions_on_appointment_and_user"
    drop_table :appointment_permissions

    remove_reference :appointments, :created_by, foreign_key: { to_table: :users }

    execute "UPDATE users SET role = 'recepcao' WHERE role = 'secretaria'"
  end
end
