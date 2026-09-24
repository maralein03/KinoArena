class PasswordResetsController < ApplicationController
  before_action :redirect_logged_in_user
  before_action :set_user_from_token, only: [ :edit, :update ]

  def new
  end

  def create
    user = User.find_by(email_address: params[:email_address].to_s.strip.downcase)

    if user.nil? || user.password_reset_throttled?
      ActivityLog.record(
        action: "password_reset_rejected",
        user: user,
        description: "Kein Link versendet fuer #{params[:email_address]}",
        ip_address: request.remote_ip
      )
    else
      UserMailer.password_reset(user, user.start_password_reset!).deliver_now
      ActivityLog.record(
        action: "password_reset_requested",
        user: user,
        target: user,
        description: "Link zum Zuruecksetzen verschickt",
        ip_address: request.remote_ip
      )
    end

    # Die Rueckmeldung ist bewusst identisch, egal ob das Konto existiert.
    # Sonst liesse sich ueber das Formular herausfinden, wer registriert ist.
    redirect_to login_path,
                notice: "Falls ein Konto zu dieser E-Mail-Adresse existiert, ist ein Link zum " \
                        "Zuruecksetzen unterwegs."
  end

  def edit
  end

  def update
    # has_secure_password ignoriert ein leeres Passwort stillschweigend,
    # deshalb wird die Eingabe hier ausdruecklich geprueft.
    if params.dig(:user, :password).blank?
      @user.errors.add(:password, "darf nicht leer sein")
      return render :edit, status: :unprocessable_entity
    end

    if @user.update(password_params)
      @user.update_column(:password_reset_sent_at, nil)
      reset_session
      ActivityLog.record(
        action: "password_reset_completed",
        user: @user,
        target: @user,
        description: "Passwort ueber Reset-Link geaendert",
        ip_address: request.remote_ip
      )
      redirect_to login_path, notice: "Passwort wurde geaendert. Bitte melde dich neu an."
    else
      # NFA-5: Fehler werden am Formular angezeigt statt als anonymer Abbruch
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def redirect_logged_in_user
    redirect_to root_path if logged_in?
  end

  # Der Token traegt seine eigene Gueltigkeit: abgelaufen oder bereits benutzt
  # (Passwort geaendert) liefert find_by_token_for nil.
  def set_user_from_token
    @token = params[:token]
    @user = User.find_by_token_for(:password_reset, @token)

    return if @user

    ActivityLog.record(
      action: "password_reset_invalid_token",
      description: "Ungueltiger oder abgelaufener Reset-Link aufgerufen",
      ip_address: request.remote_ip
    )
    redirect_to new_password_reset_path,
                alert: "Der Link ist abgelaufen oder wurde bereits verwendet. Bitte fordere einen neuen an."
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
