class SessionsController < ApplicationController
  MAX_FAILED_ATTEMPTS = 5
  LOCKOUT_PERIOD = 15.minutes

  # Bewusst prozesslokal gehalten: der Zaehler bremst Brute-Force-Versuche,
  # ohne dass dafuer Benutzerdaten geschrieben werden muessen.
  FAILED_LOGINS = ActiveSupport::Cache::MemoryStore.new(size: 512.kilobytes)

  def new
    redirect_to root_path if logged_in?
  end

  def create
    return deny_throttled_login if locked_out?

    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)

    if user&.authenticate(params[:password])
      clear_failed_attempts
      reset_session
      session[:user_id] = user.id
      @current_user = user
      log_activity("login", target: user, description: "Erfolgreiche Anmeldung")
      redirect_to root_path, notice: "Willkommen zurueck, #{user.name}!"
    else
      register_failed_attempt
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

  private

  def deny_throttled_login
    ActivityLog.record(
      action: "login_blocked",
      description: "Anmeldung nach #{MAX_FAILED_ATTEMPTS} Fehlversuchen gesperrt fuer #{params[:email_address]}",
      ip_address: request.remote_ip
    )
    flash.now[:alert] = "Zu viele Fehlversuche. Bitte warte #{LOCKOUT_PERIOD.in_minutes.to_i} Minuten " \
                        "oder setze dein Passwort zurueck."
    @email_address = params[:email_address]
    render :new, status: :too_many_requests
  end

  def throttle_key
    "login:#{request.remote_ip}:#{params[:email_address].to_s.strip.downcase}"
  end

  def locked_out?
    FAILED_LOGINS.read(throttle_key).to_i >= MAX_FAILED_ATTEMPTS
  end

  def register_failed_attempt
    FAILED_LOGINS.increment(throttle_key, 1, expires_in: LOCKOUT_PERIOD)
  end

  def clear_failed_attempts
    FAILED_LOGINS.delete(throttle_key)
  end
end
