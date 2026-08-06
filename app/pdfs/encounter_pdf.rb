class EncounterPdf < ClinicDocumentPdf
  def initialize(appointment)
    super()
    @appointment = appointment
    @encounter = appointment.encounter
    @patient = appointment.patient
  end

  private

  attr_reader :appointment, :encounter, :patient

  def unit = appointment.unit
  def professional = appointment.professional
  def title = "Registro de Atendimento"
  def verification_seed = "encounter-#{encounter.id}-#{encounter.updated_at.to_i}"

  def body
    field_row "Paciente", "#{patient.name}  ·  #{patient.age} anos  ·  CPF #{patient.cpf}"
    field_row "Convênio", patient.carteirinha.present? ? "#{patient.convenio} — carteirinha #{patient.carteirinha}" : patient.convenio
    field_row "Atendimento", "#{appointment.starts_at.strftime('%d/%m/%Y %H:%M')} — #{appointment.appointment_type} — #{professional.name} (#{professional.crm})"
    field_row "Alergias", patient.allergy

    if encounter.vitals?
      section_title "Sinais vitais"
      parts = []
      parts << "PA #{encounter.blood_pressure} mmHg" if encounter.blood_pressure.present?
      parts << "FC #{encounter.heart_rate} bpm" if encounter.heart_rate.present?
      parts << "Temp #{encounter.temperature} °C" if encounter.temperature.present?
      parts << "Peso #{encounter.weight_kg} kg" if encounter.weight_kg.present?
      parts << "Altura #{encounter.height_cm} cm" if encounter.height_cm.present?
      document.text parts.join("   ·   ")
    end

    section_title "Queixa principal" if encounter.chief_complaint.present?
    document.text encounter.chief_complaint if encounter.chief_complaint.present?

    section_title "Subjetivo"
    document.text encounter.subjective.presence || "—"

    section_title "Objetivo"
    document.text encounter.objective.presence || "—"

    section_title "Avaliação"
    document.text encounter.assessment.presence || "—"

    if encounter.diagnosis.present?
      section_title "Diagnóstico"
      document.text encounter.diagnosis
    end

    section_title "Plano"
    document.text encounter.plan.presence || "—"

    encounter.custom_fields_list.each do |field|
      section_title field["label"].presence || "Campo personalizado"
      document.text field["value"].presence || "—"
    end
  end
end
