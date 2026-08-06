class AddCustomFieldsToEncountersAndPatients < ActiveRecord::Migration[8.1]
  def change
    add_column :encounters, :custom_fields, :jsonb
    add_column :patients, :custom_fields, :jsonb
  end
end
