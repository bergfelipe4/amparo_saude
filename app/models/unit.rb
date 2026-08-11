class Unit < ApplicationRecord
  belongs_to :organization
  has_many :professionals, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :users, dependent: :nullify

  validates :name, presence: true

  def open_on?(date)
    working_days.include?(date.wday)
  end
end
