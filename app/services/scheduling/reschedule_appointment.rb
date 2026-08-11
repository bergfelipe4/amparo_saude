module Scheduling
  # Extraído de AgendaController#move: troca profissional e/ou horário mantendo
  # a duração original. Só permite remanejar consultas que ainda não começaram.
  class RescheduleAppointment
    def self.call(...) = new(...).call

    def initialize(appointment:, starts_at:, professional: nil, actor: nil)
      @appointment = appointment
      @starts_at = starts_at
      @professional = professional || appointment.professional
      @actor = actor
    end

    def call
      unless @appointment.can_reschedule?
        @appointment.errors.add(:status, "não permite remanejar essa consulta")
        return @appointment
      end

      duration = @appointment.ends_at - @appointment.starts_at

      Audited.audit_class.as_user(@actor) do
        @appointment.update(
          professional: @professional,
          starts_at: @starts_at,
          ends_at: @starts_at + duration
        )
      end

      @appointment
    end
  end
end
