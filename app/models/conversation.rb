class Conversation < ApplicationRecord
  STATUSES = %w[aberta fechada].freeze
  HISTORY_LIMIT = 20

  belongs_to :organization
  belongs_to :patient, optional: true
  has_many :messages, dependent: :destroy

  validates :phone_number, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :open, -> { where(status: "aberta") }

  def open? = status == "aberta"
  def close! = update!(status: "fechada")

  def recent_messages
    messages.order(:created_at).last(HISTORY_LIMIT)
  end
end
