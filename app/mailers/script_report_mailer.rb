class ScriptReportMailer < ApplicationMailer
  def report_created(report, user, locale, site_name)
    set_stuff(user, locale, site_name)
    subject = t('mailers.script_report.report_created_offender.subject',
                script_name: report.item.name(@locale),
                report_url: report_url(report, locale: @locale),
                site_name:)
    mail(to: user.email, subject:)
  end

  def report_rebutted(report, user, locale, site_name)
    set_stuff(user, locale, site_name)
    subject = t('mailers.script_report.report_rebutted_reporter.subject',
                script_name: report.item.name(locale),
                report_url: report_url(report, locale:),
                site_name:)
    mail(to: user.email, subject:)
  end

  def report_upheld_offender(report, user, locale, site_name)
    set_stuff(user, locale, site_name)
    subject = t('mailers.script_report.report_upheld_offender.subject',
                script_name: report.item.name(locale),
                report_url: report_url(report, locale:),
                site_name:)
    mail(to: user.email, subject:)
  end

  def report_upheld_reporter(report, author_deleted, user, locale, site_name)
    set_stuff(user, locale, site_name)
    subject = if author_deleted
                t('mailers.script_report.report_script_deleted_reporter.subject',
                  script_name: report.item.name(locale),
                  report_url: report_url(report, locale:),
                  site_name:)
              else
                t('mailers.script_report.report_upheld_reporter.subject',
                  script_name: report.item.name(locale),
                  report_url: report_url(report, locale:),
                  site_name:)
              end
    template_name = 'report_script_deleted_reporter' if author_deleted
    mail(to: user.email, subject:, template_name:)
  end

  def report_dismissed_offender(report, user, locale, site_name)
    set_stuff(user, locale, site_name)
    subject = t('mailers.script_report.report_dismissed_offender.subject',
                script_name: report.item.name(locale),
                report_url: report_url(report, locale:),
                site_name:)
    mail(to: user.email, subject:)
  end

  def report_dismissed_reporter(report, user, locale, site_name)
    set_stuff(user, locale, site_name)
    subject = t('mailers.script_report.report_dismissed_reporter.subject',
                script_name: report.item.name(locale),
                report_url: report_url(report, locale:),
                site_name:)
    mail(to: user.email, subject:)
  end

  def report_fixed_offender(report, user, locale, site_name)
    set_stuff(user, locale, site_name)
    subject = t('mailers.script_report.report_fixed_offender.subject',
                script_name: report.item.name(locale),
                report_url: report_url(report, locale:),
                site_name:)
    mail(to: user.email, subject:)
  end

  def report_fixed_reporter(report, user, locale, site_name)
    set_stuff(user, locale, site_name)
    subject = t('mailers.script_report.report_fixed_reporter.subject',
                script_name: report.item.name(locale),
                report_url: report_url(report, locale:),
                site_name:)
    mail(to: user.email, subject:)
  end

  private

  def set_stuff(user, locale, site_name)
    set_locale(locale)
    unsubscribe_for_user(user)
    @site_name = site_name
  end
end
