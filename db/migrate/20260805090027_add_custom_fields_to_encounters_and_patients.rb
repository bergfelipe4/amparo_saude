class AddCustomFieldsToEncountersAndPatients < ActiveRecord::Migration[8.1]
  def change
    add_column :encounters, :custom_fields, :json
    add_column :patients, :custom_fields, :json
  end
end
