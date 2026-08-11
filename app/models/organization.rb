class Organization < ApplicationRecord
  has_many :units, dependent: :destroy
  has_many :professionals, dependent: :destroy
  has_many :users, dependent: :destroy
  has_many :patients, dependent: :destroy
  has_many :appointments, dependent: :destroy
  has_many :prescriptions, dependent: :destroy
  has_many :conversations, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Usuário-sistema usado como autor (Audited) das ações que a secretária de
  # IA executa em nome desta organização — não faz login, só existe pra que o
  # histórico de auditoria mostre "Secretária IA" em vez de ficar sem autor.
  def ai_user
    users.find_by(role: "ia") || users.create!(
      name: "Secretária IA",
      email: "ia+#{slug}@amparosaude.internal",
      role: "ia",
      password: SecureRandom.hex(20)
    )
  end

  # whatsapp_token equivale a controlar o WhatsApp real da clínica — trate
  # como senha. Fica em texto puro por ora (Active Record Encryption não está
  # configurado neste projeto ainda); antes de vender pra clínicas de
  # verdade, criptografar com `encrypts :whatsapp_token`.
  def whatsapp_session
    whatsapp_session_id.presence || tap { update_column(:whatsapp_session_id, slug) }.whatsapp_session_id
  end
end
