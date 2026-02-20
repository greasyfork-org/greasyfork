class NotificationsController < ApplicationController
  before_action :authenticate_user!

  layout 'discussions', only: :index

  def index
    @notifications = apply_pagination(Notification.where(user: current_user).includes(:item).order(id: :desc))
  end

  def mark_all_read
    Notification.where(user: current_user).mark_read!
    redirect_back_or_to(notifications_path(current_user))
  end
end
