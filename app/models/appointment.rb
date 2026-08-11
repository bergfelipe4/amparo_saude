class Appointment < ApplicationRecord
  audited associated_with: :organization

  STATUSES = %w[aguardando confirmado atendimento concluido faltou cancelado].freeze
  TYPES = %w[Consulta Retorno].freeze

  belongs_to :organization
  belongs_to :unit
  belongs_to :professional
  belongs_to :patient
  belongs_to :follow_up_of, class_name: "Appointment", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :follow_ups, class_name: "Appointment", foreign_key: :follow_up_of_id, dependent: :nullify
  has_one :encounter, dependent: :destroy
  has_many :appointment_permissions, dependent: :destroy
  has_many :permitted_users, through: :appointment_permissions, source: :user

  validates :starts_at, :ends_at, presence: true
  validates :appointment_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }

  scope :for_day, ->(date) { where(starts_at: date.beginning_of_day..date.end_of_day) }
  scope :ordered, -> { order(:starts_at) }

  # Admin/secretária/financeiro veem tudo. Médico só vê as consultas onde é o
  # profissional responsável, mais as que foram liberadas explicitamente pra ele
  # via appointment_permissions.
  scope :visible_to, ->(user) {
    next all if user.full_access?

    left_joins(:appointment_permissions)
      .where("appointments.professional_id = :prof_id OR appointment_permissions.user_id = :user_id",
             prof_id: user.professional_id, user_id: user.id)
      .distinct
  }

  def viewable_by?(user)
    return true if user.full_access?
    return true if professional_id == user.professional_id
    appointment_permissions.exists?(user_id: user.id)
  end

  # Só quem já enxerga a consulta, e além disso é admin, criou a consulta, ou já
  # está na própria lista de permissões, pode adicionar/remover outras pessoas.
  def permissions_manageable_by?(user)
    return true if user.admin?
    return true if created_by_id.present? && created_by_id == user.id
    appointment_permissions.exists?(user_id: user.id)
  end

  STATUS_LABELS = {
    "aguardando" => "Aguardando",
    "confirmado" => "Confirmado",
    "atendimento" => "Em atendimento",
    "concluido" => "Concluído",
    "faltou" => "Faltou",
    "cancelado" => "Cancelado",
  }.freeze

  def status_label
    STATUS_LABELS.fetch(status, status)
  end

  def started?
    status == "atendimento" || status == "concluido"
  end

  def can_confirm? = status == "aguardando"
  def can_start? = status == "confirmado"
  def can_finish? = status == "atendimento"
  def can_reopen? = status == "concluido"
  def can_mark_no_show? = %w[aguardando confirmado].include?(status)
  def can_cancel? = %w[aguardando confirmado].include?(status)
  def can_reschedule? = %w[aguardando confirmado].include?(status)
  def can_schedule_follow_up? = status == "concluido" && follow_ups.none?

  def confirm! = update!(status: "confirmado")
  def start! = update!(status: "atendimento")
  def finish! = update!(status: "concluido")
  def reopen! = update!(status: "atendimento")
  def mark_no_show! = update!(status: "faltou")
  def cancel! = update!(status: "cancelado")
end
