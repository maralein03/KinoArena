class RegistrationsController < ApplicationController
  def new
    return redirect_to root_path if logged_in?

    @user = User.new
  end

  def create
    @user = User.new(registration_params)
    @user.admin = false

    if @user.save
      reset_session
      session[:user_id] = @user.id
      @current_user = @user
      log_activity("user_registered", target: @user, description: "Neues Konto erstellt")
      redirect_to root_path, notice: "Konto erstellt. Willkommen bei KinoArena, #{@user.name}!"
    else
      # NFA-5: eingegebene Werte bleiben im Formular erhalten
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:name, :email_address, :password, :password_confirmation)
  end
end
