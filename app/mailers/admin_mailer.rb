class AdminMailer < ApplicationMailer
  def delete_confirm(script, private_reason)
    mail(to: User.administrators.pluck(:email), subject: 'Script auto-deleted') do |format|
      format.text do
        render plain: "Script '#{script.default_name} (#{script_url(script, locale: nil)})' has been automatically deleted: #{private_reason}."
      end
    end
  end
end
