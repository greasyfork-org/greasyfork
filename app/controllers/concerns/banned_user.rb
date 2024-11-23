module BannedUser
  extend ActiveSupport::Concern

  BANNED_DELETE_PATH = '/users/banned_delete'.freeze

  included do
    before_action :banned?
  end

  def banned?
    user = current_user
    return false unless user.present? && user.banned?

    sign_out(user)
    show_banned_user_message(user)
    redirect_to root_path
  end

  def show_banned_user_message(user)
    moderator_action = ModeratorAction.order(id: :desc).find_by(user:)
    delete_link = new_user_session_path(return_to: BANNED_DELETE_PATH)
    flash[:html_safe] = true
    flash[:alert] = if moderator_action&.report
                      It.it('users.banned_notice.with_report', report_link: report_path(moderator_action.report), delete_link:)
                    elsif moderator_action&.reason.present?
                      It.it('users.banned_notice.with_reason', reason: moderator_action.reason, delete_link:)
                    else
                      It.it('users.banned_notice.no_report_no_reason', delete_link:)
                    end
  end
end
