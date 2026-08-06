class PatientsController < ApplicationController
  REGISTRATION_FIELDS = %i[name cpf birth_date sex phone email address convenio carteirinha guardian_name allergy].freeze

  before_action :set_patients
  before_action :set_patient, only: [:show, :update]

  def index
    @patient = @patients.first
    show_details
    render :show
  end

  def show
    show_details
  end

  def new
    @patient = Patient.new
  end

  def create
    @patient = current_user.organization.patients.new(registration_params)
    if @patient.save
      redirect_to patient_path(@patient), notice: "Paciente cadastrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @patient.update(chart_params)
      redirect_to patient_path(@patient), notice: "Ficha do paciente atualizada."
    else
      show_details
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_patients
    @patients = Patient.visible_to(current_user).where(organization: current_user.organization).order(:name)
  end

  def set_patient
    @patient = @patients.find(params[:id])
  end

  def show_details
    return unless @patient
    @appointments = @patient.appointments.visible_to(current_user).includes(:professional, :unit, :encounter).order(starts_at: :desc)
    @audits = @patient.audits.order(created_at: :desc)
  end

  def chart_params
    permitted = params.require(:patient).permit(*Patient::CHART_FIELDS, custom_fields: [:label, :value])
    permitted[:custom_fields] = compact_custom_fields(permitted[:custom_fields]) if permitted.key?(:custom_fields)
    permitted
  end

  def compact_custom_fields(fields)
    values = fields.respond_to?(:values) ? fields.values : Array(fields)
    values.map(&:to_h).reject { |f| f[:label].blank? && f[:value].blank? }
  end

  def registration_params
    params.require(:patient).permit(*REGISTRATION_FIELDS)
  end
end
