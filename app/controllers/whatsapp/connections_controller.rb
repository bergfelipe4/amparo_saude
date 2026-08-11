module Whatsapp
  # Tela de conexão do WhatsApp da clínica (QR Code + status), admin-only —
  # trocar o número conectado é uma ação sensível (equivale a mudar de conta).
  class ConnectionsController < ApplicationController
    before_action :require_admin!
    before_action :set_organization

    # O servidor do WPPConnect roda separado (fora do processo Rails) — pode
    # estar fora do ar por qualquer motivo (não iniciado, caiu, rede). Sem
    # isso, uma falha de conexão vira erro 500 tanto no polling de status
    # quanto ao tentar conectar/desconectar (confirmado em teste real).
    rescue_from Faraday::ConnectionFailed, Faraday::TimeoutError, with: :render_wppconnect_unreachable

    def show
    end

    # Gera token (se ainda não tiver) e inicia a sessão — dispara a geração do QR Code.
    def create
      client = Whatsapp::Client.build
      unless client.configured?
        return render json: { error: "WPPCONNECT_BASE_URL não configurado no servidor." }, status: :unprocessable_entity
      end

      session = @organization.whatsapp_session
      token = @organization.whatsapp_token.presence || client.generate_token(session)
      if token.blank?
        return render json: { error: "Não foi possível gerar o token de sessão." }, status: :unprocessable_entity
      end

      @organization.update!(whatsapp_token: token, whatsapp_connection_status: "iniciando")
      client.start_session(session: session, token: token)
      render json: { ok: true }
    end

    # Polling: estado atual + QR Code (se disponível).
    def status
      client = Whatsapp::Client.build
      unless client.configured? && @organization.whatsapp_token.present?
        return render json: { state: "nao_iniciado", label: "Não conectado", connected: false, qrcode: nil }
      end

      raw = client.session_status(session: @organization.whatsapp_session, token: @organization.whatsapp_token)
      mapped = Whatsapp::ConnectionStatus.call(raw["status"])
      @organization.update_column(:whatsapp_connection_status, mapped[:state])

      render json: mapped.merge(qrcode: raw["qrcode"])
    end

    def destroy
      client = Whatsapp::Client.build
      if client.configured? && @organization.whatsapp_token.present?
        client.logout_session(session: @organization.whatsapp_session, token: @organization.whatsapp_token)
        client.close_session(session: @organization.whatsapp_session, token: @organization.whatsapp_token)
      end

      @organization.update!(whatsapp_token: nil, whatsapp_connection_status: "nao_iniciado")
      redirect_to whatsapp_connection_path, notice: "WhatsApp desconectado."
    end

    private

    def set_organization
      @organization = current_user.organization
    end

    def render_wppconnect_unreachable
      respond_to do |format|
        format.json { render json: { state: "erro", label: "Servidor do WhatsApp indisponível", connected: false, qrcode: nil }, status: :service_unavailable }
        format.html { redirect_to whatsapp_connection_path, alert: "Servidor do WhatsApp indisponível no momento." }
      end
    end
  end
end
