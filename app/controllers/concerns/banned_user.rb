module BannedUser
  extend ActiveSupport::Concern

  included do
    before_action :banned?
  end

  def banned?
    return false unless current_user.present? && current_user.banned?

    sign_out current_user
    flash[:alert] = t('users.account_banned')
    root_path
  end
end
