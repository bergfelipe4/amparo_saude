class CreateProfessionals < ActiveRecord::Migration[8.1]
  def change
    create_table :professionals do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true
      t.string :name
      t.string :specialty
      t.string :crm

      t.timestamps
    end
  end
end
