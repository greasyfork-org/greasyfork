class UserMailer < ApplicationMailer
  
  def delete_confirm(user)
    mail(to: user.email, subject: 'Greasy Fork account delete confirmation') do |format|
      format.text {
        render plain: "A request was made to delete your account '#{user.name}' on Greasy Fork. To confirm this request and delete your account, go to #{user_delete_confirm_url(key: user.delete_confirmation_key)}. This must be completed in the next 24 hours or the request will be cancelled."
      }
    end
  end
end
