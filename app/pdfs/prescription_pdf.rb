class PrescriptionPdf < ClinicDocumentPdf
  def initialize(prescription)
    super()
    @prescription = prescription
    @patient = prescription.patient
  end

  private

  attr_reader :prescription, :patient

  def unit = prescription.encounter.appointment.unit
  def professional = prescription.professional
  def title = "Receita Médica"
  def verification_seed = "prescription-#{prescription.id}-#{prescription.updated_at.to_i}"

  def body
    field_row "Paciente", "#{patient.name}  ·  #{patient.age} anos  ·  CPF #{patient.cpf}"
    field_row "Emitida em", prescription.issued_at.strftime("%d/%m/%Y %H:%M")

    section_title "Prescrição"
    prescription.prescription_items.each_with_index do |item, i|
      document.move_down 6
      document.font "Helvetica", style: :bold, size: 10.5
      document.text "#{i + 1}. #{item.medication_name}"
      document.font "Helvetica", size: 9.5
      detail = [item.dosage, item.frequency, item.duration].compact_blank.join(" — ")
      document.text detail if detail.present?
      if item.instructions.present?
        document.fill_color MUTED
        document.text item.instructions, size: 9
        document.fill_color INK
      end
    end

    if prescription.notes.present?
      section_title "Observações"
      document.text prescription.notes
    end
  end
end
