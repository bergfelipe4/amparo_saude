class AddSexToPatients < ActiveRecord::Migration[8.1]
  def change
    add_column :patients, :sex, :string
  end
end
