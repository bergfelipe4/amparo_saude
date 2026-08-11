module Whatsapp
  # Processa uma mensagem recebida do WPPConnect: acha/abre a Conversation,
  # grava a mensagem, chama a IA e envia a resposta. Roda em background pra o
  # webhook poder responder 200 na hora — só a resposta da IA já demora
  # segundos, isso não pode travar a confirmação de recebimento pro WPPConnect.
  class InboundMessageJob < ApplicationJob
    queue_as :whatsapp

    # Ao reconectar, o WhatsApp Web reenvia o histórico inteiro como se fossem
    # mensagens novas (comportamento normal de qualquer sessão que loga de
    # novo) — sem esse corte, cada reconexão dispara a IA pra centenas de
    # conversas antigas de uma vez, gastando API à toa e entupindo a fila.
    BACKLOG_CUTOFF = 2.minutes

    def perform(payload)
      organization = find_organization(payload)
      return if organization.nil? || !organization.ai_enabled?
      return if backlog_message?(payload)
      return unless payload["type"] == "chat" # V1: só texto — figurinha/imagem/áudio ficam de fora por ora
      return if payload["isGroupMsg"] # a secretária atende conversa direta com o paciente, não grupo

      phone = normalize_phone(payload["from"] || payload["phone"])
      body = (payload["body"] || payload["content"] || payload["message"]).to_s
      return if phone.blank? || body.blank?

      whatsapp_message_id = payload["id"].presence
      return if whatsapp_message_id && Message.exists?(whatsapp_message_id: whatsapp_message_id)

      conversation = organization.conversations.open.find_by(phone_number: phone) ||
                     organization.conversations.create!(phone_number: phone)

      conversation.messages.create!(role: "user", content: body, whatsapp_message_id: whatsapp_message_id)
      conversation.update!(last_message_at: Time.current)

      reply = Ai::SecretaryAgent.call(conversation: conversation)
      conversation.messages.create!(role: "assistant", content: reply)

      Whatsapp::Client.build.send_message(
        session: organization.whatsapp_session_id, token: organization.whatsapp_token,
        phone: phone, message: reply
      )
    end

    private

    # V1: piloto de uma clínica só. Sem sessão configurada ainda em
    # whatsapp_session_id, cai pra primeira organização — precisa apertar essa
    # regra (match exato, sem fallback) antes de onboarding de uma 2ª clínica.
    def find_organization(payload)
      session = payload["session"].to_s
      Organization.find_by(whatsapp_session_id: session) || Organization.first
    end

    # Mantém o JID completo (com @lid ou @c.us) em vez de só o número — o
    # WhatsApp trata contatos "@lid" (identificador novo, sem número de
    # telefone real por trás) diferente de contatos "@c.us" tradicionais.
    # Cortar o sufixo e reenviar como se fosse sempre @c.us quebra o envio de
    # resposta pra contatos @lid com "No LID for user" (confirmado em teste real).
    def normalize_phone(raw)
      raw.to_s
    end

    def backlog_message?(payload)
      sent_at = payload["t"].to_i
      return false if sent_at.zero?

      Time.at(sent_at) < BACKLOG_CUTOFF.ago
    end
  end
end
