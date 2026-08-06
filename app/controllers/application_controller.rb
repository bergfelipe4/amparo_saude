class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_user!
  around_action :set_audited_user

  helper_method :current_user

  private

  def current_user
    Current.user ||= session[:user_id] && User.find_by(id: session[:user_id])
  end

  def authenticate_user!
    redirect_to login_path, alert: "Faça login para continuar." unless current_user
  end

  def require_admin!
    redirect_to root_path, alert: "Acesso restrito ao administrador." unless current_user.admin?
  end

  def set_audited_user
    Audited.audit_class.as_user(current_user) { yield }
  end
end
