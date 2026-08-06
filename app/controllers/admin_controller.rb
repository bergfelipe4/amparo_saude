class AdminController < ApplicationController
  before_action :require_admin!

  def show
    org = current_user.organization

    @units = org.units.order(:name)
    @professionals = org.professionals.includes(:unit).order(:name)
    @users = org.users.includes(:professional, :unit).order(:name)

    @patients_count = org.patients.count
    @appointments_today_count = org.appointments.for_day(Date.current).count
    @appointments_month_count = org.appointments.where(
      starts_at: Date.current.beginning_of_month..Date.current.end_of_month
    ).count

    @appointment_counts_by_professional = org.appointments.group(:professional_id).count
    @users_by_role = @users.group_by(&:role)

    @unit_stats = @units.map do |unit|
      { unit: unit, professionals: unit.professionals.size, today: unit.appointments.for_day(Date.current).count }
    end

    @recent_patients = org.patients.order(created_at: :desc).limit(6)
  end
end
