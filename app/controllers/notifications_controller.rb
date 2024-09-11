class NotificationsController < ApplicationController
  before_action :authenticate_user!

  layout 'discussions', only: :index

  def index
    @notifications = Notification.where(user: current_user).includes(:item).paginate(page: page_number)
  end

  def mark_all_read
    Notification.where(user: current_user).mark_read!
    redirect_back(fallback_location: notifications_user_path(current_user))
  end
end
