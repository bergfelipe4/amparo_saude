class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    redirect_to root_path if current_user
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      Current.user = user
      redirect_to root_path, notice: "Bem-vindo(a), #{user.name}."
    else
      flash.now[:alert] = "E-mail ou senha inválidos."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    Current.user = nil
    redirect_to login_path, notice: "Sessão encerrada."
  end
end
