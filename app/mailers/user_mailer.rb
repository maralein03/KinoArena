class UserMailer < ApplicationMailer
  def password_reset(user, token)
    @user = user
    @url = edit_password_reset_url(token)
    @validity_minutes = (User::PASSWORD_RESET_VALIDITY / 60).to_i

    mail to: user.email_address, subject: "KinoArena – Passwort zurücksetzen"
  end
end
