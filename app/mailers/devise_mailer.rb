class DeviseMailer < Devise::Mailer
  default from: 'Greasy Fork <noreply@greasyfork.org>'
  layout 'mailer'
end
