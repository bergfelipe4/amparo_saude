module Scheduling
  # Horários livres de um profissional num dia, considerando o horário de
  # funcionamento da unidade (Unit#opens_at/closes_at/working_days) menos as
  # consultas já marcadas pra ele naquele dia. Usado tanto pela tela web
  # (futuramente) quanto pelo Ai::SecretaryAgent — mesma regra, um lugar só.
  class AvailableSlots
    DEFAULT_DURATION_MINUTES = 30

    def self.call(...) = new(...).call

    def initialize(professional:, date:, duration_minutes: DEFAULT_DURATION_MINUTES)
      @professional = professional
      @unit = professional.unit
      @date = date
      @duration_minutes = duration_minutes
    end

    def call
      return [] unless @unit.open_on?(@date)

      slots = []
      cursor = combine(@unit.opens_at_minutes)
      closes_at = combine(@unit.closes_at_minutes)
      busy = booked_ranges

      while cursor + @duration_minutes.minutes <= closes_at
        slot_end = cursor + @duration_minutes.minutes
        slots << cursor if cursor > Time.current && busy.none? { |b_start, b_end| cursor < b_end && slot_end > b_start }
        cursor += @duration_minutes.minutes
      end

      slots
    end

    private

    def combine(minutes_since_midnight)
      @date.in_time_zone.beginning_of_day + minutes_since_midnight.minutes
    end

    def booked_ranges
      Appointment.where(professional: @professional)
                  .where.not(status: "cancelado")
                  .for_day(@date)
                  .pluck(:starts_at, :ends_at)
    end
  end
end
