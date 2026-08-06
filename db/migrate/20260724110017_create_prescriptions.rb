class CreatePrescriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :prescriptions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :encounter, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.references :professional, null: false, foreign_key: true
      t.datetime :issued_at
      t.text :notes

      t.timestamps
    end
  end
end
