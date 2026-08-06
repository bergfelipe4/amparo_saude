class Unit < ApplicationRecord
  belongs_to :organization
  has_many :professionals, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :users, dependent: :nullify

  validates :name, presence: true
end
