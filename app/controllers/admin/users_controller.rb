module Admin
  class UsersController < ApplicationController
    MANAGED_ROLES = %w[medico secretaria].freeze

    before_action :require_admin!
    before_action :set_user, only: [:edit, :update]
    before_action :validate_role!, only: [:create, :update]

    def index
      @users = current_user.organization.users.where(role: MANAGED_ROLES).order(:name)
    end

    def new
      @user = current_user.organization.users.new(role: "medico")
      load_form_collections
    end

    def create
      @user = current_user.organization.users.new(user_params)
      if @user.save
        redirect_to admin_users_path, notice: "#{@user.name} criado(a) com sucesso."
      else
        load_form_collections
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_collections
    end

    def update
      attrs = user_params
      attrs = attrs.except(:password) if attrs[:password].blank?
      if @user.update(attrs)
        redirect_to admin_users_path, notice: "#{@user.name} atualizado(a) com sucesso."
      else
        load_form_collections
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = current_user.organization.users.where(role: MANAGED_ROLES).find(params[:id])
    end

    def validate_role!
      role = params.dig(:user, :role)
      unless MANAGED_ROLES.include?(role)
        redirect_to admin_users_path, alert: "Perfil inválido — só é possível criar/editar médico ou secretária por aqui." and return
      end
    end

    def load_form_collections
      @units = current_user.organization.units.order(:name)
      exempt_id = @user.persisted? ? @user.id : 0
      taken_ids = current_user.organization.users.where.not(professional_id: nil).where.not(id: exempt_id).pluck(:professional_id)
      @available_professionals = current_user.organization.professionals.where.not(id: taken_ids).order(:name)
    end

    def user_params
      params.require(:user).permit(:name, :email, :password, :role, :unit_id, :professional_id, :signature)
    end
  end
end
