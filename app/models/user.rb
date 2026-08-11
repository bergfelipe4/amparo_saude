class User < ApplicationRecord
  belongs_to :organization
  belongs_to :professional, optional: true
  belongs_to :unit, optional: true
  has_secure_password
  has_one_attached :signature

  ROLES = %w[admin secretaria medico financeiro ia].freeze

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :role, inclusion: { in: ROLES }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :signature_must_be_png

  before_validation :clear_medico_only_fields

  ROLES.each do |r|
    define_method("#{r}?") { role == r }
  end

  def display_role
    { "admin" => "Administrador", "secretaria" => "Secretária", "medico" => "Médico(a)", "financeiro" => "Financeiro", "ia" => "Secretária IA" }[role]
  end

  # Perfis com acesso amplo às telas internas do dia a dia (mas não à visão exclusiva do admin).
  # "ia" entra aqui porque a secretária virtual precisa enxergar/agendar em qualquer
  # profissional da unidade, do mesmo jeito que a secretária humana já enxerga.
  def full_access?
    admin? || secretaria? || financeiro? || ia?
  end

  def initials
    name.split(" ").map { |w| w[0] }.first(2).join.upcase
  end

  private

  def signature_must_be_png
    return unless signature.attached?
    errors.add(:signature, "precisa ser um arquivo PNG") unless signature.content_type == "image/png"
  end

  def clear_medico_only_fields
    self.professional_id = nil unless medico?
  end
end
