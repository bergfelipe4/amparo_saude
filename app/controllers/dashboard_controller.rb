class DashboardController < ApplicationController
  def show
    @unit = current_user.unit || current_user.organization.units.first
    @units = current_user.organization.units

    today_scope = Appointment.visible_to(current_user).where(unit: @unit).for_day(Date.current)
    @count_today = today_scope.count
    @count_confirmadas = today_scope.where.not(status: %w[aguardando faltou]).count
    @count_aguardando = today_scope.where(status: "aguardando").count

    month_scope = Appointment.visible_to(current_user).where(unit: @unit, starts_at: Date.current.beginning_of_month..Date.current.end_of_month)
    month_total = month_scope.count
    month_faltas = month_scope.where(status: "faltou").count
    @pct_faltas = month_total.positive? ? (month_faltas.to_f / month_total * 100).round(1) : 0.0

    @upcoming = today_scope.where(status: %w[aguardando confirmado]).ordered.includes(:patient, :professional).limit(4)

    @occupancy = @units.map do |unit|
      slots = unit.professionals.count * 20
      booked = Appointment.visible_to(current_user).where(unit: unit).for_day(Date.current).count
      pct = slots.positive? ? ((booked.to_f / slots) * 100).round : 0
      { unit: unit, pct: [pct, 100].min }
    end
  end
end
