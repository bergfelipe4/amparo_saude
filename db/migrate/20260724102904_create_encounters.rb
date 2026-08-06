class CreateEncounters < ActiveRecord::Migration[8.1]
  def change
    create_table :encounters do |t|
      t.references :appointment, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.references :professional, null: false, foreign_key: true
      t.text :subjective
      t.text :objective
      t.text :assessment
      t.text :plan

      t.timestamps
    end
  end
end
