class Patient < ApplicationRecord
  audited associated_with: :organization

  # MariaDB não tem um tipo JSON nativo de verdade (a coluna vira LONGTEXT), então o
  # Rails não faz o cast automático — precisamos serializar explicitamente.
  serialize :custom_fields, coder: JSON, type: Array

  belongs_to :organization
  has_many :appointments, dependent: :destroy
  has_many :encounters, dependent: :destroy
  has_many :prescriptions, dependent: :destroy

  validates :name, presence: true
  validates :convenio, presence: true

  CHART_FIELDS = %i[blood_type chronic_conditions current_medications family_history emergency_contact_name emergency_contact_phone].freeze
  SEX_OPTIONS = ["Feminino", "Masculino"].freeze

  # Admin/secretária/financeiro veem todos os pacientes. Médico só vê pacientes
  # com quem tem ao menos uma consulta visível (própria ou liberada por permissão).
  scope :visible_to, ->(user) {
    next all if user.full_access?
    where(id: Appointment.visible_to(user).select(:patient_id))
  }

  def age
    return nil unless birth_date
    ((Date.current - birth_date) / 365.25).floor
  end

  def initials
    name.split(" ").map { |w| w[0] }.first(2).join.upcase
  end

  def chart_present?
    CHART_FIELDS.any? { |f| send(f).present? } || custom_fields_list.any?
  end

  # Campos extras específicos deste paciente — não existem em nenhum outro registro.
  def custom_fields_list
    Array(custom_fields).select { |f| f["label"].present? || f["value"].present? }
  end
end
