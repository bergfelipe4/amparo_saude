class CreatePatients < ActiveRecord::Migration[8.1]
  def change
    create_table :patients do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.string :cpf
      t.date :birth_date
      t.string :phone
      t.string :email
      t.string :address
      t.string :convenio
      t.string :carteirinha
      t.string :allergy
      t.string :guardian_name

      t.timestamps
    end
  end
end
