module Scheduling
  # Extraído do padrão transition! do EncountersController. Cobre só as
  # transições "simples" (sem efeito colateral, como criar prontuário) —
  # start/finish continuam exclusivos do fluxo de atendimento presencial.
  class ChangeStatus
    EVENTS = {
      "confirm" => [:can_confirm?, :confirm!],
      "reopen" => [:can_reopen?, :reopen!],
      "no_show" => [:can_mark_no_show?, :mark_no_show!],
      "cancel" => [:can_cancel?, :cancel!]
    }.freeze

    def self.call(...) = new(...).call

    def initialize(appointment:, event:, actor: nil)
      @appointment = appointment
      @event = event.to_s
      @actor = actor
    end

    def call
      guard, bang = EVENTS[@event]
      unless guard
        @appointment.errors.add(:base, "evento de status desconhecido: #{@event}")
        return @appointment
      end

      unless @appointment.public_send(guard)
        @appointment.errors.add(:status, "não permite esse evento no estado atual (#{@appointment.status_label})")
        return @appointment
      end

      Audited.audit_class.as_user(@actor) { @appointment.public_send(bang) }
      @appointment
    end
  end
end
