class SessionsController < ApplicationController
  def new
    redirect_to root_path if logged_in?
  end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id
      @current_user = user
      log_activity("login", target: user, description: "Erfolgreiche Anmeldung")
      redirect_to root_path, notice: "Willkommen zurueck, #{user.name}!"
    else
      ActivityLog.record(
        action: "login_failed",
        description: "Fehlgeschlagener Anmeldeversuch fuer #{params[:email_address]}",
        ip_address: request.remote_ip
      )
      flash.now[:alert] = "E-Mail-Adresse oder Passwort ist falsch."
      @email_address = params[:email_address]
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    log_activity("logout", target: current_user, description: "Abmeldung") if logged_in?
    reset_session
    redirect_to root_path, notice: "Du wurdest abgemeldet."
  end
end
