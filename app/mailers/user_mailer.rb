class UserMailer < ApplicationMailer
  def delete_confirm(user, site_name)
    mail(to: user.email, subject: t('users.delete.confirmation_email.subject', site_name: site_name)) do |format|
      format.text do
        render plain: t('users.delete.confirmation_email.body', site_name: site_name, user_name: user.name, url: user_delete_confirm_url(key: user.delete_confirmation_key))
      end
    end
  end
end
