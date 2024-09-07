class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = Notification.where(user: current_user).includes(:item).  paginate(page: page_number)
  end

  def mark_all_read
    Notification.where(user: current_user).mark_read!
    redirect_to :index
  end
end
