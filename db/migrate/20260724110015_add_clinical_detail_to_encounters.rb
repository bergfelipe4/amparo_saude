class AddClinicalDetailToEncounters < ActiveRecord::Migration[8.1]
  def change
    add_column :encounters, :chief_complaint, :text
    add_column :encounters, :diagnosis, :string
    add_column :encounters, :blood_pressure, :string
    add_column :encounters, :heart_rate, :integer
    add_column :encounters, :temperature, :decimal, precision: 4, scale: 1
    add_column :encounters, :weight_kg, :decimal, precision: 5, scale: 1
    add_column :encounters, :height_cm, :decimal, precision: 5, scale: 1
  end
end
