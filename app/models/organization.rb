class Organization < ApplicationRecord
  has_many :units, dependent: :destroy
  has_many :professionals, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :patients, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :prescriptions, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
