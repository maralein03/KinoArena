module Admin
  class ActivityLogsController < BaseController
    def index
      authorize ActivityLog
      @logs = policy_scope(ActivityLog).includes(:user).recent_first
      @logs = @logs.where(action: params[:action_filter]) if params[:action_filter].present?
      @logs = @logs.where(user_id: params[:user_id]) if params[:user_id].present?
      @logs = @logs.limit(200)

      @actions = ActivityLog.distinct.order(:action).pluck(:action)
      @users = User.order(:email_address)
    end
  end
end
