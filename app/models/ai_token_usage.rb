class AiTokenUsage < ApplicationRecord
  belongs_to :organization
  belongs_to :conversation

  validates :model, presence: true
end
