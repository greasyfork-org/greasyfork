class UserBanAndDeleteJob < ApplicationJob
  queue_as :default

  def perform(user_id, private_reason, public_reason)
    begin
      user = User.find(user_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    return if user.banned?

    user.ban!(automod: true, reason: public_reason, private_reason:, ban_related: true)
    AdminMailer.delete_confirm(user, private_reason).deliver_later
  end
end
