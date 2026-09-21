module SignInHelper
  def sign_in_as(user, password: "passwort123")
    post login_path, params: { email_address: user.email_address, password: password }
  end

  def sign_out
    delete logout_path
  end
end
