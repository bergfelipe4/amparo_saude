module Scheduling
  # Mesma lógica transacional que AppointmentsController#create já usava,
  # extraída pra service pra que a tela web e o Ai::SecretaryAgent marquem
  # consulta pelo mesmo caminho — sem duplicar regra de negócio.
  class BookAppointment
    DEFAULT_DURATION_MINUTES = 30

    def self.call(...) = new(...).call

    def initialize(organization:, unit:, professional:, patient:, starts_at:, duration_minutes: DEFAULT_DURATION_MINUTES, appointment_type: "Consulta", actor: nil)
      @organization = organization
      @unit = unit
      @professional = professional
      @patient = patient
      @starts_at = starts_at
      @duration_minutes = duration_minutes
      @appointment_type = appointment_type
      @actor = actor
    end

    # Retorna o Appointment — persistido se deu certo, com erros em .errors se não.
    def call
      Audited.audit_class.as_user(@actor) do
        @organization.appointments.create(
          unit: @unit,
          professional: @professional,
          patient: @patient,
          appointment_type: @appointment_type,
          starts_at: @starts_at,
          ends_at: @starts_at + @duration_minutes.minutes,
          status: "aguardando",
          created_by: @actor
        )
      end
    end
  end
end
