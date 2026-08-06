class Current < ActiveSupport::CurrentAttributes
  attribute :user

  def organization
    user&.organization
  end
end
