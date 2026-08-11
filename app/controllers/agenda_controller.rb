class AgendaController < ApplicationController
  DAY_START_MIN = 6 * 60
  DAY_END_MIN = 19 * 60
  ROW_MIN = 30
  ROW_HEIGHT_PX = 48
  SNAP_MIN = 15

  helper_method :slot_top, :slot_height

  before_action :set_unit

  def show
    @date = parse_date(params[:date]) || Date.current
    @selected_professional_ids = selected_professional_ids
    @professionals = @all_professionals.select { |p| @selected_professional_ids.include?(p.id) }
    @appointments = Appointment.visible_to(current_user)
                                .where(unit: @unit, professional_id: @professionals.map(&:id))
                                .for_day(@date)
                                .includes(:patient, :professional)
    @rows = (DAY_END_MIN - DAY_START_MIN) / ROW_MIN
  end

  def move
    unless current_user.full_access?
      return render json: { error: "Sem permissão pra remanejar consultas." }, status: :forbidden
    end

    appointment = Appointment.where(unit: @unit).find(params[:id])
    professional = @all_professionals.find { |p| p.id == params[:professional_id].to_i }
    starts_at = parse_time(params[:starts_at])
    unless professional && starts_at
      return render json: { error: "Dados inválidos." }, status: :unprocessable_entity
    end

    appointment = Scheduling::RescheduleAppointment.call(
      appointment: appointment, starts_at: starts_at, professional: professional, actor: current_user
    )

    if appointment.errors.empty?
      render json: { ok: true }
    else
      render json: { error: appointment.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end
  end

  def slot_top(time)
    minutes = time.hour * 60 + time.min
    ((minutes - DAY_START_MIN).to_f / ROW_MIN) * ROW_HEIGHT_PX + 2
  end

  def slot_height(starts_at, ends_at)
    (((ends_at - starts_at) / 60).to_f / ROW_MIN) * ROW_HEIGHT_PX - 4
  end

  private

  def set_unit
    @unit = current_user.unit || current_user.organization.units.first
    @all_professionals = @unit.professionals.order(:name)
  end

  def selected_professional_ids
    ids = Array(params[:professional_ids]).map(&:to_i)
    ids.presence || @all_professionals.map(&:id)
  end

  def parse_date(str)
    Date.parse(str) if str.present?
  rescue ArgumentError
    nil
  end

  def parse_time(str)
    return nil if str.blank?
    Time.zone.parse(str)
  rescue ArgumentError
    nil
  end
end
