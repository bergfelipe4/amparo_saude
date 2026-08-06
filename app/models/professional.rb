class Professional < ApplicationRecord
  belongs_to :organization
  belongs_to :unit
  has_one :user, dependent: :nullify
  has_many :appointments, dependent: :destroy
  has_many :encounters, dependent: :destroy
  has_many :prescriptions, dependent: :destroy

  validates :name, presence: true
  validates :specialty, presence: true
  validates :crm, presence: true

  def short_name
    name.sub(/\ADra?\.\s*/, "")
  end
end
