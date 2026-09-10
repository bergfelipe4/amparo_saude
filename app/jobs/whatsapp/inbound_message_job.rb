module Whatsapp
  # Processa uma mensagem recebida do WPPConnect: acha/abre a Conversation,
  # grava a mensagem, chama a IA e envia a resposta. Roda em background pra o
  # webhook poder responder 200 na hora — só a resposta da IA já demora
  # segundos, isso não pode travar a confirmação de recebimento pro WPPConnect.
  class InboundMessageJob < ApplicationJob
    queue_as :whatsapp

    PHONE_LOCKS = {}
    PHONE_LOCKS_GUARD = Mutex.new

    # Em produção, o Solid Queue impede concorrência até entre processos.
    # O mutex abaixo mantém a mesma garantia no adapter Async do development.
    limits_concurrency to: 1,
                       key: ->(payload) { "whatsapp:#{payload['session']}:#{payload['from'] || payload['phone']}" },
                       duration: 5.minutes

    # Ao reconectar, o WhatsApp Web reenvia o histórico inteiro como se fossem
    # mensagens novas (comportamento normal de qualquer sessão que loga de
    # novo) — sem esse corte, cada reconexão dispara a IA pra centenas de
    # conversas antigas de uma vez, gastando API à toa e entupindo a fila.
    BACKLOG_CUTOFF = 2.minutes

    # A IA começa a trabalhar sem exibir presença. Depois de 1..5s o
    # "digitando..." aparece e fica visível por no máximo 10s, mesmo se a
    # chamada ao provedor demorar mais ou falhar.
    PRE_TYPING_DELAY_RANGE = 1.0..5.0
    TYPING_CHARS_PER_SECOND = 12.0
    MIN_TYPING_DURATION = 1.0
    MAX_TYPING_DURATION = 10.0

    def perform(payload)
      organization = find_organization(payload)
      return if organization.nil? || !organization.ai_enabled?
      return if backlog_message?(payload)
      return unless payload["type"] == "chat" # V1: só texto — figurinha/imagem/áudio ficam de fora por ora
      return if payload["isGroupMsg"] # a secretária atende conversa direta com o paciente, não grupo

      phone = normalize_phone(payload["from"] || payload["phone"])
      body = (payload["body"] || payload["content"] || payload["message"]).to_s
      return if phone.blank? || body.blank?
      return unless organization.ai_responds_to_phone?(phone)

      phone_lock_for(organization, phone).synchronize do
        whatsapp_message_id = payload["id"].presence
        return if whatsapp_message_id && Message.exists?(whatsapp_message_id: whatsapp_message_id)

        conversation = organization.conversations.open.find_by(phone_number: phone) ||
                       organization.conversations.create!(phone_number: phone)

        associate_sender_patient(conversation, organization, phone)

        conversation.messages.create!(role: "user", content: body, whatsapp_message_id: whatsapp_message_id)
        conversation.update!(last_message_at: Time.current)

        client = Whatsapp::Client.build
        session, token = organization.whatsapp_session_id, organization.whatsapp_token
        reply = generate_reply_with_typing(
          conversation: conversation, client: client, session: session,
          token: token, phone: phone
        )
        conversation.messages.create!(role: "assistant", content: reply)
        client.send_message(session: session, token: token, phone: phone, message: reply)
      end
    end

    private

    def phone_lock_for(organization, phone)
      key = "#{organization.id}:#{phone}"
      PHONE_LOCKS_GUARD.synchronize { PHONE_LOCKS[key] ||= Mutex.new }
    end

    def associate_sender_patient(conversation, organization, phone)
      patient = Patients::FindByPhone.call(organization: organization, phone: phone)
      conversation.update!(patient: patient) if conversation.patient_id != patient&.id
    end

    def generate_reply_with_typing(conversation:, client:, session:, token:, phone:)
      agent_thread = Thread.new do
        Rails.application.executor.wrap do
          ActiveRecord::Base.connection_pool.with_connection do
            Ai::SecretaryAgent.call(conversation: conversation)
          end
        end
      end
      agent_thread.report_on_exception = false

      sleep(pre_typing_delay_seconds)
      typing_started_at = monotonic_time
      typing_enabled = safely_set_typing(
        client: client, session: session, token: token, phone: phone, typing: true
      )

      if agent_thread.join(MAX_TYPING_DURATION)
        reply = agent_thread.value
        remaining = MAX_TYPING_DURATION - (monotonic_time - typing_started_at)
        sleep([ typing_delay_seconds(reply), remaining ].min) if typing_enabled && remaining.positive?
        reply
      else
        safely_set_typing(client: client, session: session, token: token, phone: phone, typing: false)
        typing_enabled = false
        agent_thread.value
      end
    ensure
      safely_set_typing(client: client, session: session, token: token, phone: phone, typing: false) if typing_enabled
    end

    def safely_set_typing(client:, session:, token:, phone:, typing:)
      client.set_typing(session: session, token: token, phone: phone, typing: typing)
      true
    rescue StandardError => error
      Rails.logger.warn("[Whatsapp::InboundMessageJob] Não foi possível alterar 'digitando' para #{phone}: #{error.class}: #{error.message}")
      false
    end

    def pre_typing_delay_seconds
      rand * (PRE_TYPING_DELAY_RANGE.end - PRE_TYPING_DELAY_RANGE.begin) + PRE_TYPING_DELAY_RANGE.begin
    end

    def monotonic_time
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def typing_delay_seconds(text)
      (text.to_s.length / TYPING_CHARS_PER_SECOND + rand(0.3..1.2)).clamp(
        MIN_TYPING_DURATION, MAX_TYPING_DURATION
      )
    end

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
