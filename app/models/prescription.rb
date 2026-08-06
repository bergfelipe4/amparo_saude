class Prescription < ApplicationRecord
  audited associated_with: :patient

  belongs_to :organization
  belongs_to :encounter
  belongs_to :patient
  belongs_to :professional
  has_many :prescription_items, -> { order(:position) }, dependent: :destroy, inverse_of: :prescription
  accepts_nested_attributes_for :prescription_items, reject_if: :all_blank, allow_destroy: true

  validates :issued_at, presence: true
  validates :prescription_items, presence: true

  before_validation { self.issued_at ||= Time.current }
end
