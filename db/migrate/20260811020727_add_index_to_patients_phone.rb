class AddIndexToPatientsPhone < ActiveRecord::Migration[8.1]
  def change
    add_index :patients, :phone
  end
end
