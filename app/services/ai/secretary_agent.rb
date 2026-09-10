module Ai
  # Agente de function-calling que atende pelo WhatsApp: recebe o histórico de
  # uma Conversation, conversa com o LLM via OpenRouterClient (já com
  # proxy/privacidade configurados) e executa as ferramentas que ele pedir,
  # delegando sempre pros mesmos services que a tela web usa (Scheduling::*,
  # Patients::FindOrRegister) — nunca inventa uma ação por conta própria.
  class SecretaryAgent
    MAX_TOOL_ROUNDS = 5
    DEFAULT_DURATION_MINUTES = 30
    SELECTED_PATIENT_ID_KEY = "scheduling_patient_id"
    SELECTED_RECIPIENT_KEY = "scheduling_recipient"
    RECIPIENT_QUESTION_KEY = "recipient_question_asked_at"
    RECIPIENTS = %w[titular outra_pessoa].freeze
    UNVERIFIED_SUCCESS_PATTERN = /\b(cadastrei|cadastro\s+(?:foi\s+)?(?:conclu[ií]do|realizado)|agendei|marquei|agendamento\s+(?:foi\s+)?(?:conclu[ií]do|realizado)|(?:sua|a)\s+consulta\s+(?:foi\s+)?(?:agendada|marcada)|consulta\s+(?:agendada|marcada)\s+(?:com\s+sucesso|para)|est[aá]\s+agendad[ao])\b/i

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
          description: "Seleciona quem receberá o atendimento. Use recipient=titular para o dono do WhatsApp e recipient=outra_pessoa para cadastrar outra pessoa. Para titular já identificado, nome e convênio não são necessários; para titular novo ou outra pessoa, peça nome completo e convênio.",
          parameters: {
            type: "object",
            properties: {
              recipient: { type: "string", enum: RECIPIENTS, description: "titular para quem está falando; outra_pessoa para terceiro." },
              name: { type: "string" },
              cpf: { type: "string" },
              birth_date: { type: "string", description: "AAAA-MM-DD" },
              sex: { type: "string", enum: Patient::SEX_OPTIONS },
              convenio: { type: "string" },
              email: { type: "string" },
              phone: { type: "string", description: "Telefone próprio da outra pessoa, somente se ela informar." }
            },
            required: %w[recipient]
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
              appointment_type: { type: "string", enum: Appointment::TYPES },
              confirmed_by_patient: { type: "boolean", description: "true somente depois de o paciente confirmar profissional, data e horário." }
            },
            required: %w[patient_id professional_id starts_at appointment_type confirmed_by_patient]
          }
        }
      }
    ].freeze

    def self.call(...) = new(...).call

    def initialize(conversation:)
      @conversation = conversation
      @organization = conversation.organization
      @sender_patient = Patients::FindByPhone.call(
        organization: @organization,
        phone: @conversation.phone_number
      )
      @conversation.update!(patient: @sender_patient) if @conversation.patient_id != @sender_patient&.id
      @verified_patient_action = nil
      @verified_appointment = nil
    end

    def call
      return ask_recipient_question if should_ask_recipient_question?

      client = OpenRouterClient.build
      messages = build_messages

      MAX_TOOL_ROUNDS.times do
        message = request_message(client, messages)
        return fallback_message unless message

        tool_calls = message["tool_calls"]
        return verified_response(message["content"].to_s) if tool_calls.blank?

        messages << message.slice("role", "content", "tool_calls", "reasoning", "reasoning_details")
        tool_calls.each { |tool_call| messages << tool_result_message(tool_call) }
      end

      fallback_message
    end

    private

    def request_message(client, messages)
      response = client.chat(parameters: chat_parameters(messages))
      register_token_usage(response)
      response.dig("choices", 0, "message")
    end

    def fallback_message
      "Desculpa, não consegui concluir agora. Um atendente humano vai continuar essa conversa em breve."
    end

    def chat_parameters(messages)
      {
        model: Ai::ModelCatalog.fetch(@organization.ai_model)[:model],
        messages: messages,
        tools: TOOL_DEFINITIONS,
        reasoning: {
          effort: ENV.fetch("OPENROUTER_REASONING_EFFORT", "low")
        },
        provider: {
          data_collection: ENV["OPENROUTER_DATA_COLLECTION"],
          zdr: ActiveModel::Type::Boolean.new.cast(ENV["OPENROUTER_ZDR"])
        }
      }
    end

    def build_messages
      [ { role: "system", content: system_prompt } ] + @conversation.recent_messages.map { |m| m.to_llm_message.stringify_keys }
    end

    def system_prompt
      <<~PROMPT
        Você é a secretária virtual da #{@organization.name}, atendendo pacientes pelo WhatsApp.
        Data de hoje: #{I18n.l(Date.current, format: :long)}.
        Profissionais disponíveis (use o id exato nas ferramentas):
        #{professionals_summary}

        Identificação desta conversa:
        #{patient_context_summary}

        Regras:
        - Seja cordial e objetiva, frases curtas, tom de secretária de clínica.
        - Nunca invente horário, disponibilidade ou dado de paciente — sempre confira com as ferramentas.
        - Se o número estiver identificado e ainda não houver paciente selecionado para este atendimento, chame o titular pelo primeiro nome e pergunte se a consulta é para ele(a) ou para outra pessoa. Não presuma a resposta.
        - Se o número não estiver identificado, siga normalmente e colete nome completo e convênio antes de cadastrar.
        - Para atendimento do titular, chame cadastrar_ou_achar_paciente com recipient=titular. Para terceiro, use recipient=outra_pessoa; nunca reutilize o cadastro do titular para outra pessoa.
        - Antes de marcar, confirme com o paciente o profissional, data e horário escolhidos.
        - Só diga que cadastrou ou agendou depois que a ferramenta correspondente retornar sucesso. Use exatamente o nome retornado pela ferramenta.
        - Se não conseguir resolver algo, diga que um atendente humano vai continuar a conversa.
        #{custom_instructions}
      PROMPT
    end

    def custom_instructions
      instructions = @organization.ai_instructions.to_s.strip
      return "" if instructions.blank?

      "Instruções adicionais da clínica (siga apenas se não conflitarem com as regras acima):\n#{instructions}"
    end

    def register_token_usage(response)
      usage = response["usage"].to_h
      input = usage["prompt_tokens"].to_i
      output = usage["completion_tokens"].to_i
      return if input.zero? && output.zero?

      @organization.ai_token_usages.create!(conversation: @conversation, model: Ai::ModelCatalog.fetch(@organization.ai_model)[:model], input_tokens: input, output_tokens: output, total_tokens: usage["total_tokens"].to_i)
    rescue StandardError => error
      Rails.logger.warn("[Ai::SecretaryAgent] Não foi possível registrar uso de tokens: #{error.message}")
    end

    def professionals_summary
      @organization.professionals.map { |p| "- id #{p.id}: #{p.name} (#{p.specialty})" }.join("\n")
    end

    def patient_context_summary
      recognized = @sender_patient
      selected = selected_patient

      recognized_line = if recognized
        "- Titular identificado pelo número: id #{recognized.id}, nome #{recognized.name}."
      else
        "- Nenhum paciente foi identificado pelo número."
      end

      selected_line = if selected
        "- Paciente já selecionado neste atendimento: id #{selected.id}, nome #{selected.name}, tipo #{@conversation.context[SELECTED_RECIPIENT_KEY]}."
      else
        "- Ainda não há paciente selecionado para este atendimento."
      end

      [ recognized_line, selected_line ].join("\n")
    end

    def should_ask_recipient_question?
      @sender_patient.present? && selected_patient.nil? &&
        @conversation.context.to_h[RECIPIENT_QUESTION_KEY].blank?
    end

    def ask_recipient_question
      context = @conversation.context.to_h.merge(RECIPIENT_QUESTION_KEY => Time.current.iso8601)
      @conversation.update!(context: context)
      first_name = @sender_patient.name.to_s.split.first
      "Olá, #{first_name}! Encontrei seu cadastro. Você quer agendar uma consulta para você ou para outra pessoa?"
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
      recipient = args["recipient"].to_s
      return { error: "informe se o atendimento é para titular ou outra pessoa" } unless RECIPIENTS.include?(recipient)

      patient, created = if recipient == "titular"
        find_or_register_sender(args)
      else
        find_or_register_other_person(args)
      end

      return { error: patient.errors.full_messages.to_sentence } if !patient.persisted? || patient.errors.any?

      select_patient(patient, recipient)
      @verified_patient_action = { patient: patient, created: created, recipient: recipient }
      { patient_id: patient.id, name: patient.name, recipient: recipient, result: created ? "created" : "found" }
    end

    def book_appointment(args)
      patient = @organization.patients.find_by(id: args["patient_id"])
      professional = @organization.professionals.find_by(id: args["professional_id"])
      return { error: "paciente ou profissional não encontrado" } unless patient && professional
      return { error: "selecione primeiro para quem é a consulta" } unless selected_patient&.id == patient.id
      return { error: "confirme profissional, data e horário com o paciente antes de marcar" } unless boolean(args["confirmed_by_patient"])

      starts_at = Time.zone.parse(args["starts_at"])
      return { error: "horário inválido" } unless starts_at
      slots = Scheduling::AvailableSlots.call(professional: professional, date: starts_at.to_date)
      return { error: "esse horário não está mais disponível; consulte a disponibilidade novamente" } unless slots.any? { |slot| slot.to_i == starts_at.to_i }

      appointment = Scheduling::BookAppointment.call(
        organization: @organization, unit: professional.unit, professional: professional,
        patient: patient, starts_at: starts_at, duration_minutes: DEFAULT_DURATION_MINUTES,
        appointment_type: args["appointment_type"] || "Consulta", actor: @organization.ai_user,
        conversation: @conversation
      )

      return { error: appointment.errors.full_messages.to_sentence } unless appointment.persisted?

      @verified_appointment = appointment
      clear_selected_patient
      {
        appointment_id: appointment.id,
        patient_id: patient.id,
        patient_name: patient.name,
        professional_name: professional.name,
        starts_at: appointment.starts_at.iso8601,
        status: appointment.status_label
      }
    end

    def find_or_register_sender(args)
      existing = @sender_patient
      return [ existing, false ] if existing

      attributes = patient_attributes(args)
      return [ invalid_patient("nome completo e convênio são obrigatórios"), false ] unless registration_data_present?(attributes)

      patient = Patients::FindOrRegister.call(
        organization: @organization,
        phone: @conversation.phone_number,
        attributes: attributes
      )
      if patient.persisted?
        @sender_patient = patient
        @conversation.update!(patient: patient)
      end
      [ patient, patient.persisted? ]
    end

    def find_or_register_other_person(args)
      attributes = patient_attributes(args)
      return [ invalid_patient("nome completo e convênio são obrigatórios"), false ] unless registration_data_present?(attributes)

      current = selected_patient
      if current && @conversation.context[SELECTED_RECIPIENT_KEY] == "outra_pessoa" && same_name?(current.name, attributes[:name])
        current.update(attributes.except(:name, :phone).compact_blank)
        return [ current, false ]
      end

      existing = @organization.patients.find_by(cpf: attributes[:cpf]) if attributes[:cpf].present?
      return [ existing, false ] if existing

      patient = @organization.patients.new(attributes)
      patient.save
      [ patient, patient.persisted? ]
    end

    def patient_attributes(args)
      {
        name: args["name"], cpf: args["cpf"], birth_date: args["birth_date"],
        sex: args["sex"], convenio: args["convenio"], email: args["email"],
        phone: args["phone"]
      }.compact_blank
    end

    def registration_data_present?(attributes)
      attributes[:name].present? && attributes[:convenio].present?
    end

    def invalid_patient(message)
      @organization.patients.new.tap { |patient| patient.errors.add(:base, message) }
    end

    def same_name?(left, right)
      left.to_s.squish.casecmp?(right.to_s.squish)
    end

    def select_patient(patient, recipient)
      context = @conversation.context.to_h.merge(
        SELECTED_PATIENT_ID_KEY => patient.id,
        SELECTED_RECIPIENT_KEY => recipient
      )
      @conversation.update!(context: context)
    end

    def clear_selected_patient
      context = @conversation.context.to_h.except(SELECTED_PATIENT_ID_KEY, SELECTED_RECIPIENT_KEY)
      @conversation.update!(context: context)
    end

    def selected_patient
      id = @conversation.context.to_h[SELECTED_PATIENT_ID_KEY]
      @organization.patients.find_by(id: id) if id.present?
    end

    def boolean(value)
      ActiveModel::Type::Boolean.new.cast(value)
    end

    def verified_response(content)
      return appointment_confirmation if @verified_appointment
      return patient_registration_confirmation if @verified_patient_action&.dig(:created)
      return fallback_unverified_action if content.match?(UNVERIFIED_SUCCESS_PATTERN)

      content.presence || fallback_message
    end

    def appointment_confirmation
      appointment = @verified_appointment
      "Solicitação de consulta registrada para #{appointment.patient.name}, com #{appointment.professional.name}, em #{appointment.starts_at.strftime('%d/%m/%Y às %H:%M')}. Ela está em espera, aguardando a confirmação do profissional responsável. Assim que houver a confirmação, aviso você por aqui."
    end

    def patient_registration_confirmation
      patient = @verified_patient_action[:patient]
      "Cadastro de #{patient.name} concluído. Agora posso procurar os horários disponíveis para a consulta."
    end

    def fallback_unverified_action
      "Ainda não concluí esse cadastro ou agendamento no sistema. Posso continuar a conferência dos dados antes de finalizar."
    end
  end
end
