class ScriptInvitationMailer < ApplicationMailer
  def invite(invitation, site_name)
    locale = invitation.invited_user.locale&.code || :en
    mail(
      to: invitation.invited_user.email,
      subject: t('scripts.invitations.subject',
                 site_name: site_name,
                 script_name: invitation.script.name(locale),
                 locale: locale)
    ) do |format|
      format.html do
        render plain: t('scripts.invitations.body',
                        site_name: site_name,
                        script_name: invitation.script.name(locale),
                        script_url: script_url(invitation.script, locale: locale),
                        accept_url: accept_invitation_script_url(invitation.script, locale: locale))
      end
    end
  end
end
