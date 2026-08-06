class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name
      t.string :address
      t.string :phone

      t.timestamps
    end
  end
end
