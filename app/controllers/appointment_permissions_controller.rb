class AppointmentPermissionsController < ApplicationController
  before_action :set_appointment
  before_action :authorize_management!

  def create
    user = current_user.organization.users.where(role: %w[medico secretaria]).find_by(id: params[:user_id])

    if user.nil?
      redirect_to encounter_path(@appointment), alert: "Selecione um médico ou secretária válido." and return
    end

    grant = @appointment.appointment_permissions.new(user: user, granted_by: current_user)
    if grant.save
      redirect_to encounter_path(@appointment), notice: "#{user.name} agora tem acesso a esta consulta."
    else
      redirect_to encounter_path(@appointment), alert: grant.errors.full_messages.to_sentence
    end
  end

  def destroy
    grant = @appointment.appointment_permissions.find(params[:id])
    grant.destroy
    redirect_to encounter_path(@appointment), notice: "Acesso removido."
  end

  private

  def set_appointment
    @appointment = Appointment.where(organization: current_user.organization).find(params[:appointment_id])
  end

  def authorize_management!
    unless @appointment.permissions_manageable_by?(current_user)
      redirect_to encounter_path(@appointment), alert: "Você não tem permissão para gerenciar os acessos desta consulta."
    end
  end
end
