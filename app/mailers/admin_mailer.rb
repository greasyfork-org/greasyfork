class AdminMailer < ApplicationMailer
  def delete_confirm(item, private_reason)
    mail(to: User.administrators.pluck(:email), subject: 'Script auto-deleted') do |format|
      format.text do
        if item.is_a?(Script)
          render plain: "Script '#{item.default_name}' (#{script_url(item, locale: nil)}) has been automatically deleted: #{private_reason}."
        else
          render plain: "User '#{item.name}' (#{user_url(item, locale: nil)})' has been automatically deleted: #{private_reason}."
        end
      end
    end
  end
end
