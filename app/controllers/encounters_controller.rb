class EncountersController < ApplicationController
  before_action :set_unit
  before_action :set_filtered_appointments, only: [:index, :show, :update]
  before_action :set_appointment, except: [:index]

  def index
    @appointment = preferred_appointment
    render :show
  end

  def show
    render_appointment_panel
  end

  def update
    unless @appointment.encounter
      redirect_to encounter_path(@appointment, **filter_params), alert: "Inicie o atendimento antes de registrar o prontuário." and return
    end

    @encounter = @appointment.encounter
    if @encounter.update(encounter_params)
      redirect_to encounter_path(@appointment, **filter_params), notice: "Prontuário salvo."
    else
      set_filtered_appointments
      render_appointment_panel(status: :unprocessable_entity)
    end
  end

  def destroy
    unless current_user.full_access?
      redirect_to encounters_path, alert: "Você não tem permissão para excluir consultas." and return
    end

    appointment_id = @appointment.id
    @appointment.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove("appointment_#{appointment_id}"),
          turbo_stream.update("modal", "")
        ]
      end
      format.html { redirect_to encounters_path, notice: "Consulta excluída." }
    end
  end

  def confirm
    transition!(:can_confirm?, :confirm!, "Consulta confirmada.", "Só é possível confirmar uma consulta aguardando confirmação.")
  end

  def start
    if @appointment.can_start?
      @appointment.encounter || @appointment.create_encounter!(patient: @appointment.patient, professional: @appointment.professional)
      @appointment.start!
      redirect_to encounter_path(@appointment), notice: "Atendimento iniciado."
    else
      redirect_to encounter_path(@appointment), alert: "Só é possível iniciar uma consulta confirmada."
    end
  end

  def finish
    if !@appointment.can_finish?
      redirect_to encounter_path(@appointment), alert: "Só é possível finalizar uma consulta em atendimento."
    elsif @appointment.encounter&.complete?
      @appointment.finish!
      redirect_to encounter_path(@appointment), notice: "Atendimento finalizado."
    else
      redirect_to encounter_path(@appointment), alert: "Preencha ao menos Avaliação e Plano antes de finalizar."
    end
  end

  def reopen
    transition!(:can_reopen?, :reopen!, "Atendimento reaberto para edição.", "Só é possível reabrir uma consulta concluída.")
  end

  def no_show
    transition!(:can_mark_no_show?, :mark_no_show!, "Falta registrada.", "Não é possível marcar falta nesse status.")
  end

  def cancel
    transition!(:can_cancel?, :cancel!, "Consulta cancelada.", "Não é possível cancelar nesse status.")
  end

  def schedule_follow_up
    unless @appointment.can_schedule_follow_up?
      redirect_to encounter_path(@appointment), alert: "Esta consulta precisa estar concluída e sem retorno já agendado." and return
    end

    starts_at = parse_follow_up_time || (@appointment.starts_at + 7.days)
    duration = @appointment.ends_at - @appointment.starts_at

    follow_up = Appointment.create!(
      organization: @appointment.organization, unit: @appointment.unit, professional: @appointment.professional,
      patient: @appointment.patient, starts_at: starts_at, ends_at: starts_at + duration,
      appointment_type: "Retorno", status: "aguardando", follow_up_of: @appointment, created_by: current_user
    )
    redirect_to encounter_path(follow_up), notice: "Retorno agendado para #{I18n.l(starts_at, format: :short)}."
  end

  def print
    send_data EncounterPdf.new(@appointment).render,
              filename: "prontuario-#{@appointment.patient.name.parameterize}-#{@appointment.starts_at.strftime('%Y%m%d')}.pdf",
              type: "application/pdf", disposition: "inline"
  end

  private

  def render_appointment_panel(status: :ok)
    if modal_request?
      render :modal, layout: false, status: status
    else
      render :show, status: status
    end
  end

  def modal_request?
    turbo_frame_request? && turbo_frame_request_id == "modal"
  end

  def transition!(guard, bang_method, success_msg, failure_msg)
    if @appointment.public_send(guard)
      @appointment.public_send(bang_method)
      redirect_to encounter_path(@appointment), notice: success_msg
    else
      redirect_to encounter_path(@appointment), alert: failure_msg
    end
  end

  def parse_follow_up_time
    return nil if params[:starts_at].blank?
    Time.zone.parse(params[:starts_at])
  rescue ArgumentError
    nil
  end

  def set_unit
    @unit = current_user.unit || current_user.organization.units.first
    @professionals = @unit.professionals.order(:name)
  end

  def set_filtered_appointments
    scope = Appointment.visible_to(current_user).where(unit: @unit).includes(:patient, :professional, :encounter)
    scope = scope.where(professional_id: params[:professional_id]) if params[:professional_id].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(appointment_type: params[:appointment_type]) if params[:appointment_type].present?
    if params[:q].present?
      scope = scope.joins(:patient).where("patients.name ILIKE ?", "%#{params[:q]}%")
    end

    today_appointments = scope.for_day(Date.current).ordered
    if today_appointments.exists?
      @appointments = today_appointments
      @showing_recent_fallback = false
    else
      # Não há consultas hoje — mostra os atendimentos mais recentes pra tela não ficar vazia.
      @appointments = scope.order(starts_at: :desc).limit(24)
      @showing_recent_fallback = true
    end
  end

  def set_appointment
    @appointment = Appointment.where(unit: @unit).find(params[:appointment_id] || params[:id])
    unless @appointment.viewable_by?(current_user)
      redirect_to encounters_path, alert: "Você não tem permissão para ver esta consulta." and return
    end
  end

  def preferred_appointment
    @appointments.find { |a| a.status == "atendimento" } || @appointments.first
  end

  def filter_params
    params.slice(:professional_id, :status, :appointment_type, :q).permit!.to_h
  end
  helper_method :filter_params

  def encounter_params
    permitted = params.require(:encounter).permit(
      :chief_complaint, :subjective, :objective, :assessment, :plan, :diagnosis,
      :blood_pressure, :heart_rate, :temperature, :weight_kg, :height_cm,
      custom_fields: [:label, :value]
    )
    permitted[:custom_fields] = compact_custom_fields(permitted[:custom_fields]) if permitted.key?(:custom_fields)
    permitted
  end

  def compact_custom_fields(fields)
    values = fields.respond_to?(:values) ? fields.values : Array(fields)
    values.map(&:to_h).reject { |f| f[:label].blank? && f[:value].blank? }
  end
end
