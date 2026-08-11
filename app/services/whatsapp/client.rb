module Whatsapp
  # Cliente pra API REST do WPPConnect (https://wppconnect.io). Token e
  # sessão são por organização (Organization#whatsapp_session_id/whatsapp_token)
  # — cada clínica conecta o próprio WhatsApp. Sem WPPCONNECT_BASE_URL
  # configurado (ex: ainda validando o resto do fluxo em dev), envio de
  # mensagem só loga em vez de tentar enviar de verdade.
  class Client
    def self.build
      new(base_url: ENV["WPPCONNECT_BASE_URL"], secret_key: ENV["WPPCONNECT_SECRET_KEY"])
    end

    def initialize(base_url:, secret_key:)
      @base_url = base_url.to_s.strip
      @secret_key = secret_key.to_s.strip
    end

    def configured?
      @base_url.present? && @secret_key.present?
    end

    # Gera o token de autenticação de uma sessão (uma vez só, ele não expira).
    def generate_token(session)
      return nil unless configured?

      response = connection.post("/api/#{session}/#{@secret_key}/generate-token")
      response.body.is_a?(Hash) ? response.body["token"] : nil
    end

    # Inicia (ou retoma) a sessão do WhatsApp — dispara a geração do QR Code.
    def start_session(session:, token:)
      return {} unless configured?

      authed_post("/api/#{session}/start-session", token, { waitQrCode: false })
    end

    # Estado atual: status bruto do WPPConnect + qrcode em data URL (se houver).
    def session_status(session:, token:)
      return {} unless configured?

      response = connection.get("/api/#{session}/status-session") { |req| authorize(req, token) }
      response.body.is_a?(Hash) ? response.body : {}
    end

    def logout_session(session:, token:)
      authed_post("/api/#{session}/logout-session", token) if configured?
    end

    def close_session(session:, token:)
      authed_post("/api/#{session}/close-session", token) if configured?
    end

    def send_message(session:, token:, phone:, message:)
      unless configured? && token.present?
        Rails.logger.info("[Whatsapp::Client] (modo log, sessão não conectada) para #{phone}: #{message}")
        return true
      end

      authed_post("/api/#{session}/send-message", token, { phone: phone, message: message }).present?
    end

    private

    def authed_post(path, token, body = nil)
      response = connection.post(path) do |req|
        authorize(req, token)
        req.body = body if body
      end
      response.body
    end

    def authorize(req, token)
      req.headers["Authorization"] = "Bearer #{token}"
    end

    def connection
      @connection ||= Faraday.new(url: @base_url) do |f|
        f.request :json
        f.response :json, content_type: /\bjson$/
        f.adapter Faraday.default_adapter
      end
    end
  end
end
