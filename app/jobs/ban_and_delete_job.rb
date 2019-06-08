class BanAndDeleteJob < ApplicationJob
  def perform(script_id, disallowed_code_id)
    script = Script.find(script_id)
    script.users.each do |user|
      ma_ban = ModeratorAction.new
      ma_ban.moderator = User.administrators.first
      ma_ban.user = user
      ma_ban.action = 'Ban'
      ma_ban.reason = 'Auto-ban due to disallowed code'
      ma_ban.save!
      user.banned = true
      user.save!
    end
    script.locked = true
    script.delete_reason = 'Auto-delete due to disallowed code'
    script.script_delete_type_id = 2
    script.save(validate: false)
    User.administrators.each do |admin|
      ActionMailer::Base.mail(from: 'noreply@greasyfork.org', to: admin.email, subject: "Script auto-deleted", body: "Script '#{script.default_name} (#{script_url(script, locale: nil)})' has been automatically deleted.").deliver
    end
  end
end