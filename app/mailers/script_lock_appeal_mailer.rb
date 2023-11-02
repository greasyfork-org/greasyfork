class ScriptLockAppealMailer < ApplicationMailer
  helper ScriptsHelper

  def dismiss(appeal, user, site_name)
    @appeal = appeal
    @site_name = site_name
    set_locale_for_user(user)
    mail(to: user.email, subject: t('mailers.script_lock_appeal.dismiss.subject', site_name:))
  end

  def unlock(appeal, user, site_name)
    @appeal = appeal
    @site_name = site_name
    set_locale_for_user(user)
    mail(to: user.email, subject: t('mailers.script_lock_appeal.unlock.subject', site_name:))
  end
end
