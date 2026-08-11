module Ai
  # Agente de function-calling que atende pelo WhatsApp: recebe o histórico de
  # uma Conversation, conversa com o LLM via OpenRouterClient (já com
  # proxy/privacidade configurados) e executa as ferramentas que ele pedir,
  # delegando sempre pros mesmos services que a tela web usa (Scheduling::*,
  # Patients::FindOrRegister) — nunca inventa uma ação por conta própria.
  class SecretaryAgent
    MAX_TOOL_ROUNDS = 5
    DEFAULT_DURATION_MINUTES = 30

    TOOL_DEFINITIONS = [
      {
        type: "function",
        function: {
          name: "checar_disponibilidade",
          description: "Lista horários livres de um profissional numa data específica.",
          parameters: {
            type: "object",
            properties: {
              professional_id: { type: "integer", description: "Id do profissional, conforme listado no contexto." },
              date: { type: "string", description: "Data no formato AAAA-MM-DD." }
            },
            required: %w[professional_id date]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "cadastrar_ou_achar_paciente",
          description: "Busca o paciente pelo telefone da conversa; se não existir, cadastra com os dados informados. Sempre peça nome completo e convênio antes de chamar.",
          parameters: {
            type: "object",
            properties: {
              name: { type: "string" },
              cpf: { type: "string" },
              birth_date: { type: "string", description: "AAAA-MM-DD" },
              sex: { type: "string", enum: Patient::SEX_OPTIONS },
              convenio: { type: "string" },
              email: { type: "string" }
            },
            required: %w[name convenio]
          }
        }
      },
      {
        type: "function",
        function: {
          name: "marcar_consulta",
          description: "Marca uma consulta pra um paciente já cadastrado/achado, num horário confirmado como livre.",
          parameters: {
            type: "object",
            properties: {
              patient_id: { type: "integer" },
              professional_id: { type: "integer" },
              starts_at: { type: "string", description: "Data e hora ISO 8601, ex: 2026-08-21T14:00:00-03:00" },
              appointment_type: { type: "string", enum: Appointment::TYPES }
            },
            required: %w[patient_id professional_id starts_at appointment_type]
          }
        }
      }
    ].freeze

    def self.call(...) = new(...).call

    def initialize(conversation:)
      @conversation = conversation
      @organization = conversation.organization
    end

    def call
      client = OpenRouterClient.build
      messages = build_messages

      MAX_TOOL_ROUNDS.times do
        message = request_message(client, messages)
        return fallback_message unless message

        tool_calls = message["tool_calls"]
        return message["content"].to_s if tool_calls.blank?

        messages << message.slice("role", "content", "tool_calls")
        tool_calls.each { |tool_call| messages << tool_result_message(tool_call) }
      end

      fallback_message
    end

    private

    def request_message(client, messages)
      response = client.chat(parameters: chat_parameters(messages))
      response.dig("choices", 0, "message")
    end

    def fallback_message
      "Desculpa, não consegui concluir agora. Um atendente humano vai continuar essa conversa em breve."
    end

    def chat_parameters(messages)
      {
        model: ENV["OPENROUTER_MODEL"],
        messages: messages,
        tools: TOOL_DEFINITIONS,
        provider: {
          data_collection: ENV["OPENROUTER_DATA_COLLECTION"],
          zdr: ActiveModel::Type::Boolean.new.cast(ENV["OPENROUTER_ZDR"])
        }
      }
    end

    def build_messages
      [{ role: "system", content: system_prompt }] + @conversation.recent_messages.map { |m| m.to_llm_message.stringify_keys }
    end

    def system_prompt
      <<~PROMPT
        Você é a secretária virtual da #{@organization.name}, atendendo pacientes pelo WhatsApp.
        Data de hoje: #{I18n.l(Date.current, format: :long)}.
        Profissionais disponíveis (use o id exato nas ferramentas):
        #{professionals_summary}

        Regras:
        - Seja cordial e objetiva, frases curtas, tom de secretária de clínica.
        - Nunca invente horário, disponibilidade ou dado de paciente — sempre confira com as ferramentas.
        - Antes de cadastrar um paciente novo, colete nome completo e convênio.
        - Antes de marcar, confirme com o paciente o profissional, data e horário escolhidos.
        - Se não conseguir resolver algo, diga que um atendente humano vai continuar a conversa.
      PROMPT
    end

    def professionals_summary
      @organization.professionals.map { |p| "- id #{p.id}: #{p.name} (#{p.specialty})" }.join("\n")
    end

    def tool_result_message(tool_call)
      {
        role: "tool",
        tool_call_id: tool_call["id"],
        content: execute_tool(tool_call).to_json
      }
    end

    def execute_tool(tool_call)
      name = tool_call.dig("function", "name")
      args = JSON.parse(tool_call.dig("function", "arguments").presence || "{}")

      case name
      when "checar_disponibilidade" then check_availability(args)
      when "cadastrar_ou_achar_paciente" then find_or_register_patient(args)
      when "marcar_consulta" then book_appointment(args)
      else { error: "ferramenta desconhecida: #{name}" }
      end
    rescue => e
      { error: e.message }
    end

    def check_availability(args)
      professional = @organization.professionals.find_by(id: args["professional_id"])
      return { error: "profissional não encontrado" } unless professional

      date = Date.parse(args["date"])
      slots = Scheduling::AvailableSlots.call(professional: professional, date: date)
      { professional_id: professional.id, date: date.to_s, slots: slots.map { |s| s.iso8601 } }
    rescue ArgumentError
      { error: "data inválida" }
    end

    def find_or_register_patient(args)
      patient = Patients::FindOrRegister.call(
        organization: @organization,
        phone: @conversation.phone_number,
        attributes: {
          name: args["name"], cpf: args["cpf"], birth_date: args["birth_date"],
          sex: args["sex"], convenio: args["convenio"], email: args["email"]
        }.compact
      )

      return { error: patient.errors.full_messages.to_sentence } unless patient.persisted?

      @conversation.update(patient: patient) if @conversation.patient_id.nil?
      { patient_id: patient.id, name: patient.name }
    end

    def book_appointment(args)
      patient = @organization.patients.find_by(id: args["patient_id"])
      professional = @organization.professionals.find_by(id: args["professional_id"])
      return { error: "paciente ou profissional não encontrado" } unless patient && professional

      starts_at = Time.zone.parse(args["starts_at"])
      return { error: "horário inválido" } unless starts_at

      appointment = Scheduling::BookAppointment.call(
        organization: @organization, unit: professional.unit, professional: professional,
        patient: patient, starts_at: starts_at, duration_minutes: DEFAULT_DURATION_MINUTES,
        appointment_type: args["appointment_type"] || "Consulta", actor: @organization.ai_user
      )

      return { error: appointment.errors.full_messages.to_sentence } unless appointment.persisted?

      { appointment_id: appointment.id, starts_at: appointment.starts_at.iso8601, status: appointment.status_label }
    end
  end
end
