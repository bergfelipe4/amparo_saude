module Scheduling
  # Extraído de AgendaController#move: troca profissional e/ou horário mantendo
  # a duração original. Só permite remanejar consultas que ainda não começaram.
  class RescheduleAppointment
    def self.call(...) = new(...).call

    def initialize(appointment:, starts_at:, professional: nil, appointment_type: nil, actor: nil)
      @appointment = appointment
      @starts_at = starts_at
      @professional = professional || appointment.professional
      @appointment_type = appointment_type.presence || appointment.appointment_type
      @actor = actor
    end

    def call
      unless @appointment.can_reschedule?
        @appointment.errors.add(:status, "não permite remanejar essa consulta")
        return @appointment
      end

      unless Appointment::TYPES.include?(@appointment_type)
        @appointment.errors.add(:appointment_type, "não é válido")
        return @appointment
      end

      duration = @appointment.ends_at - @appointment.starts_at
      ends_at = @starts_at + duration

      if conflicting_appointment?(ends_at)
        @appointment.errors.add(:starts_at, "conflita com outra consulta desse profissional")
        return @appointment
      end

      Audited.audit_class.as_user(@actor) do
        @appointment.update(
          professional: @professional,
          starts_at: @starts_at,
          ends_at: ends_at,
          appointment_type: @appointment_type
        )
      end

      @appointment
    end

    private

    def conflicting_appointment?(ends_at)
      Appointment.where(professional: @professional)
                 .where.not(id: @appointment.id)
                 .where.not(status: "cancelado")
                 .where("starts_at < ? AND ends_at > ?", ends_at, @starts_at)
                 .exists?
    end
  end
end
