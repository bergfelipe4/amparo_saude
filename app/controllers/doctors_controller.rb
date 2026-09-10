class DoctorsController < ApplicationController
  before_action :set_professionals
  before_action :set_professional, only: [ :show, :update ]

  def index
    @professional = @professionals.first
    load_details
    render :show
  end

  def show
    load_details
  end

  def update
    unless signature_manageable?
      redirect_to doctor_path(@professional), alert: "Você não tem permissão para alterar esta assinatura." and return
    end

    user = @professional.user
    unless user
      redirect_to doctor_path(@professional), alert: "Este médico ainda não possui uma conta vinculada." and return
    end

    if user.update(signature_params)
      redirect_to doctor_path(@professional, section: "assinatura"), notice: "Assinatura atualizada."
    else
      load_details
      flash.now[:alert] = user.errors.full_messages.to_sentence
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_professionals
    scope = current_user.organization.professionals.includes(:unit, :user).order(:name)
    @professionals = current_user.medico? ? scope.where(id: current_user.professional_id) : scope
  end

  def set_professional
    @professional = @professionals.find(params[:id])
  end

  def load_details
    return unless @professional

    @appointments = @professional.appointments.merge(Appointment.visible_to(current_user))
                                 .includes(:patient, :unit, :encounter).order(starts_at: :desc)
    @patients = Patient.visible_to(current_user)
                       .where(id: @professional.appointments.select(:patient_id))
                       .order(:name)
    @upcoming_appointments = @appointments.where("starts_at >= ?", Time.current).limit(5)
  end

  def signature_manageable?
    current_user.admin? || current_user.professional_id == @professional.id
  end

  def signature_params
    params.require(:user).permit(:signature)
  end
end
