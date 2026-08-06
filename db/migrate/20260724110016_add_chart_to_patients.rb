class AddChartToPatients < ActiveRecord::Migration[8.1]
  def change
    add_column :patients, :blood_type, :string
    add_column :patients, :chronic_conditions, :text
    add_column :patients, :current_medications, :text
    add_column :patients, :family_history, :text
    add_column :patients, :emergency_contact_name, :string
    add_column :patients, :emergency_contact_phone, :string
  end
end
