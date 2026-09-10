# Não herda de ApplicationController de propósito: esse endpoint é chamado
# pelo WPPConnect, não por uma sessão de usuário logado — não tem
# authenticate_user! nem CSRF de formulário.
class WhatsappController < ActionController::Base
  skip_forgery_protection

  def webhook
    return head :unauthorized unless valid_secret?
    return head :ok if boolean_param?(:fromMe) || boolean_param?(:isGroupMsg)
    return head :ok unless params[:type] == "chat"

    payload = params.permit(
      :event, :session, :id, :type, :t, :from, :phone,
      :body, :content, :message, :isGroupMsg, :fromMe
    ).to_h.deep_stringify_keys
    Whatsapp::InboundMessageJob.perform_later(payload)
    head :ok
  end

  private

  # Sem segredo configurado (ex: ainda em desenvolvimento local) o webhook
  # aceita tudo — em produção, ENV["WHATSAPP_WEBHOOK_SECRET"] é obrigatório.
  def valid_secret?
    expected = ENV["WHATSAPP_WEBHOOK_SECRET"].to_s
    return true if expected.blank?

    request.headers["X-Webhook-Secret"].to_s == expected
  end

  def boolean_param?(key)
    ActiveModel::Type::Boolean.new.cast(params[key])
  end
end
