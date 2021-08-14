class ScriptLockAppealMailer < ApplicationMailer
  def dismiss(appeal, _site_name)
    subject_lambda = lambda { |_locale|
      'Your script deletion appeal has been dismissed'
    }
    text_lambda = lambda { |locale|
      "Your appeal of the deletion of #{appeal.script.name(locale)} has been dismissed by a moderator. The script will remain locked."
    }
    mail_to_authors(appeal, subject_lambda, text_lambda)
  end

  def unlock(appeal, _site_name)
    subject_lambda = lambda { |_locale|
      'Your script has been restored'
    }
    text_lambda = lambda { |locale|
      "Your appeal of the deletion of #{appeal.script.name(locale)} has been upheld by a moderator. The script has been undeleted and is now accessible again."
    }
    mail_to_authors(appeal, subject_lambda, text_lambda)
  end

  def mail_to_authors(appeal, subject_lambda, text_lambda)
    appeal.script.users.each do |user|
      mail(to: user.email, subject: subject_lambda.call(user.available_locale_code)) do |format|
        format.text do
          render plain: text_lambda.call(user.available_locale_code)
        end
      end
    end
  end
end
