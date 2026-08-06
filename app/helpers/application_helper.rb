module ApplicationHelper
  FIELD_LABELS = {
    "name" => "Nome", "phone" => "Telefone", "email" => "E-mail", "address" => "Endereço",
    "convenio" => "Convênio", "carteirinha" => "Carteirinha", "allergy" => "Alergia",
    "guardian_name" => "Responsável", "status" => "Status", "starts_at" => "Horário de início",
    "ends_at" => "Horário de término", "subjective" => "Subjetivo", "objective" => "Objetivo",
    "assessment" => "Avaliação", "plan" => "Plano",
  }.freeze

  def audit_field_label(field)
    FIELD_LABELS[field] || field.humanize
  end

  def audit_actor_name(audit)
    actor = audit.user # String or an ActiveRecord model, per Audited::Audit#user_as_string
    case actor
    when String then actor
    when nil then "Sistema"
    else actor.respond_to?(:name) ? actor.name : actor.to_s
    end
  end

  def audit_actor_initials(audit)
    name = audit_actor_name(audit)
    name.split(" ").map { |w| w[0] }.first(2).join.upcase
  end

  def audit_dot_class(audit)
    return "create" if audit.action == "create"
    return "status" if audit.audited_changes.key?("status")
    ""
  end

  def audit_permission_description(audit)
    user = User.find_by(id: audit.audited_changes["user_id"])
    name = user&.name || "um usuário removido"
    audit.action == "create" ? "Acesso concedido a #{name}" : "Acesso removido de #{name}"
  end
end
