require "excon"
require "faraday/excon"
require "faraday/retry"

# Fábrica única pro client da OpenAI/OpenRouter. Centralizar aqui garante que
# qualquer chamada (agora ou nas futuras features de IA) sempre passa pelo
# mesmo proxy de saída — sem depender de cada chamador lembrar de configurar.
#
# faraday.proxy= só sabe falar com proxy HTTP (CONNECT); pra SOCKS5 (Tor) é
# preciso trocar o adapter de transporte inteiro pro Excon, que tem suporte
# nativo a socks5_proxy sem monkey-patchear Net::HTTP globalmente.
class OpenRouterClient
  # Circuito Tor pode cair no meio de uma requisição (característica normal
  # da rede, não bug nosso) — confirmado num teste real (Faraday::ConnectionFailed
  # por EOFError). Um retry curto resolve, já que a próxima tentativa monta
  # conexão/circuito novo.
  RETRY_OPTIONS = {
    max: 2,
    interval: 0.5,
    interval_randomness: 0.5,
    backoff_factor: 2,
    exceptions: [Faraday::ConnectionFailed, Faraday::TimeoutError]
  }.freeze

  def self.build
    proxy_url = ENV["OPENROUTER_PROXY_URL"].to_s.strip

    OpenAI::Client.new do |faraday|
      faraday.request :retry, RETRY_OPTIONS if proxy_url.present?
      faraday.adapter :excon, socks5_proxy: proxy_url if proxy_url.present?
    end
  end
end
