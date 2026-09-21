class ApplicationController < ActionController::Base
  include Pundit::Authorization

  helper_method :current_user, :logged_in?

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] ? User.find_by(id: session[:user_id]) : nil
  end

  def logged_in?
    current_user.present?
  end

  def require_user
    unless logged_in?
      flash[:alert] = "Bitte melde dich zuerst an."
      redirect_to login_path
    end
  end
end