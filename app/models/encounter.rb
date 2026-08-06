class Encounter < ApplicationRecord
  audited associated_with: :patient

  belongs_to :appointment
  belongs_to :patient
  belongs_to :professional
  has_many :prescriptions, dependent: :destroy

  # Intentionally no presence validation on the clinical fields: the record is created
  # the moment an appointment starts, and the professional fills it in progressively.
  # Completeness is enforced only when finishing the appointment (see Appointment#can_finish?
  # combined with EncountersController#finish).

  def complete?
    assessment.present? && plan.present?
  end

  def vitals?
    blood_pressure.present? || heart_rate.present? || temperature.present? || weight_kg.present? || height_cm.present?
  end

  # Campos extras específicos deste atendimento — não existem em nenhum outro registro.
  def custom_fields_list
    Array(custom_fields).select { |f| f["label"].present? || f["value"].present? }
  end
end
