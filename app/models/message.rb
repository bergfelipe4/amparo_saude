class Message < ApplicationRecord
  ROLES = %w[user assistant system tool].freeze

  belongs_to :conversation

  validates :role, inclusion: { in: ROLES }

  # Formato aceito direto pelo endpoint de chat completions da OpenRouter/OpenAI.
  def to_llm_message
    { role: role, content: content }.tap do |msg|
      msg[:tool_calls] = tool_calls if tool_calls.present?
    end
  end
end
