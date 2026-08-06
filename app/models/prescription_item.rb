class PrescriptionItem < ApplicationRecord
  belongs_to :prescription

  validates :medication_name, presence: true
  validates :dosage, presence: true

  def descriptor
    [medication_name, dosage, frequency, duration].compact_blank.join(" — ")
  end
end
