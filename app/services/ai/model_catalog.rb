module Ai
  class ModelCatalog
    OPTIONS = {
      "gpt_4o_mini" => { name: "ChatGPT 4o mini", model: "openai/gpt-4o-mini", tier: "Menor custo" },
      "gpt_5_mini" => { name: "ChatGPT 5 mini", model: "openai/gpt-5-mini", tier: "Equilibrado" },
      "claude_sonnet" => { name: "Claude Sonnet 4.5", model: "anthropic/claude-sonnet-4.5", tier: "Avançado" },
      "gpt_5_2" => { name: "ChatGPT 5.2", model: "openai/gpt-5.2", tier: "Máxima qualidade" }
    }.freeze

    def self.fetch(key)
      OPTIONS.fetch(key.to_s, OPTIONS.fetch("gpt_4o_mini"))
    end
  end
end
