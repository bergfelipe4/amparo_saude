class PrescriptionsController < ApplicationController
  def create
    unit = current_user.unit || current_user.organization.units.first
    appointment = Appointment.where(unit: unit).find(params[:appointment_id])

    unless appointment.viewable_by?(current_user)
      redirect_to encounters_path, alert: "Você não tem permissão para ver esta consulta." and return
    end

    unless appointment.encounter
      redirect_to encounter_path(appointment), alert: "Inicie o atendimento antes de emitir uma receita." and return
    end

    prescription = appointment.encounter.prescriptions.build(prescription_params)
    prescription.organization = appointment.organization
    prescription.patient = appointment.patient
    prescription.professional = appointment.professional

    if prescription.save
      redirect_to encounter_path(appointment), notice: "Receita emitida."
    else
      redirect_to encounter_path(appointment), alert: "Não foi possível emitir a receita: #{prescription.errors.full_messages.to_sentence}"
    end
  end

  def print
    prescription = Prescription.where(organization: current_user.organization).find(params[:id])
    unless prescription.encounter.appointment.viewable_by?(current_user)
      redirect_to encounters_path, alert: "Você não tem permissão para ver esta receita." and return
    end
    send_data PrescriptionPdf.new(prescription).render,
              filename: "receita-#{prescription.patient.name.parameterize}-#{prescription.issued_at.strftime('%Y%m%d')}.pdf",
              type: "application/pdf", disposition: "inline"
  end

  private

  def prescription_params
    params.require(:prescription).permit(:notes, prescription_items_attributes: [:medication_name, :dosage, :frequency, :duration, :instructions])
  end
end
