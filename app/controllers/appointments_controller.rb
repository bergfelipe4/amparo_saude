class AppointmentsController < ApplicationController
  DURATIONS = [15, 20, 30, 45, 60].freeze

  before_action :set_form_data

  def new
    @appointment = Appointment.new(starts_at: default_starts_at, appointment_type: "Consulta")
    @new_patient = Patient.new
    @patient_mode = "existing"
    @duration = 30
  end

  def create
    @patient_mode = params[:patient_mode] == "new" ? "new" : "existing"
    @new_patient = current_user.organization.patients.new(@patient_mode == "new" ? registration_params : {})
    @duration = DURATIONS.include?(params[:duration].to_i) ? params[:duration].to_i : 30

    @appointment = current_user.organization.appointments.new(
      unit: @unit,
      professional_id: params[:professional_id],
      appointment_type: params[:appointment_type],
      starts_at: parsed_starts_at,
      status: "aguardando",
      created_by: current_user
    )
    @appointment.ends_at = @appointment.starts_at + @duration.minutes if @appointment.starts_at

    saved = ActiveRecord::Base.transaction do
      if @patient_mode == "new"
        raise ActiveRecord::Rollback unless @new_patient.save
        @appointment.patient = @new_patient
      else
        @appointment.patient = @patients.find_by(id: params[:patient_id])
        unless @appointment.patient
          @appointment.errors.add(:base, "Selecione um paciente ou cadastre um novo.")
          raise ActiveRecord::Rollback
        end
      end

      raise ActiveRecord::Rollback unless @appointment.save
      true
    end

    if saved
      redirect_to encounter_path(@appointment), notice: "Consulta agendada para #{@appointment.patient.name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_form_data
    @unit = current_user.unit || current_user.organization.units.first
    @professionals = @unit.professionals.order(:name)
    @patients = Patient.visible_to(current_user).where(organization: current_user.organization).order(:name)
  end

  def default_starts_at
    now = Time.current
    now.change(min: (now.min / 15.0).ceil * 15 % 60, hour: now.min > 45 ? now.hour + 1 : now.hour)
  end

  def parsed_starts_at
    return nil if params[:starts_at].blank?
    Time.zone.parse(params[:starts_at])
  rescue ArgumentError
    nil
  end

  def registration_params
    params.require(:patient).permit(*PatientsController::REGISTRATION_FIELDS)
  end
end
