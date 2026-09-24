class UsersController < ApplicationController
  before_action :require_user
  before_action :set_user, only: [ :show, :edit, :update, :destroy ]

  def index
    authorize User
    @users = policy_scope(User).order(:email_address)
  end

  def show
    authorize @user
    @bookings = @user.bookings.includes(showtime: [ :movie, :auditorium ]).recent_first
  end

  def edit
    authorize @user
  end

  def update
    authorize @user
    was_admin = @user.admin?

    if @user.update(user_params)
      log_profile_change(was_admin)
      redirect_to user_path(@user), notice: "Profil wurde aktualisiert."
    else
      # NFA-5: Formular wird mit den eingegebenen Werten erneut angezeigt
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user
    deleting_self = @user == current_user
    email = @user.email_address
    @user.destroy!

    log_activity("user_deleted", description: "Konto #{email} geloescht")

    if deleting_self
      reset_session
      redirect_to root_path, notice: "Dein Konto wurde geloescht."
    else
      redirect_to users_path, notice: "Konto #{email} wurde geloescht."
    end
  end

  private

  # Eine Rollenaenderung ist die sicherheitsrelevanteste Aenderung am Konto und
  # bekommt deshalb einen eigenen Protokolleintrag.
  def log_profile_change(was_admin)
    if was_admin == @user.admin?
      log_activity("user_updated", target: @user, description: "Profil aktualisiert")
    else
      log_activity("user_role_changed", target: @user,
                   description: "#{@user.email_address}: #{was_admin ? 'Administrator' : 'Kunde'} → #{@user.role_name}")
    end
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    attrs = params.require(:user).permit(*policy(@user).permitted_attributes)
    attrs = attrs.except(:password, :password_confirmation) if attrs[:password].blank?
    attrs
  end
end
