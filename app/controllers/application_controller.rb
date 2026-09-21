class ApplicationController < ActionController::Base
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  helper_method :current_user, :logged_in?, :admin?

  private

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] ? User.find_by(id: session[:user_id]) : nil
  end

  def logged_in?
    current_user.present?
  end

  def admin?
    current_user&.admin?
  end

  def require_user
    unless logged_in?
      flash[:alert] = "Bitte melde dich zuerst an."
      redirect_to login_path
    end
  end

  def require_admin
    return require_user unless logged_in?

    user_not_authorized unless admin?
  end

  def pundit_user
    current_user
  end

  def log_activity(action, target: nil, description: nil)
    ActivityLog.record(
      action: action,
      user: current_user,
      target: target,
      description: description,
      ip_address: request.remote_ip
    )
  end

  def user_not_authorized
    flash[:alert] = "Zugriff verweigert. Du hast keine Berechtigung für diese Seite."
    redirect_to(request.referer.presence || root_path)
  end

  def record_not_found
    log_activity("record_not_found", description: "Aufruf einer nicht existierenden Ressource: #{request.path}")
    render "errors/not_found", status: :not_found
  end
end
