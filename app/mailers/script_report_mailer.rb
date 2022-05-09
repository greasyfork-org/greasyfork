class ScriptReportMailer < ApplicationMailer
  def report_created(report, site_name)
    subject = lambda { |user|
      locale = user.available_locale_code
      t('mailers.script_report.report_created_offender.subject',
        locale:,
        script_name: report.item.name(locale),
        report_url: report_url(report, locale:),
        site_name:)
    }
    mail_to_offenders(report:, subject:, site_name:)
  end

  def report_rebutted(report, site_name)
    subject = lambda { |user|
      locale = user.available_locale_code
      t('mailers.script_report.report_rebutted_reporter.subject',
        locale:,
        script_name: report.item.name(locale),
        report_url: report_url(report, locale:),
        site_name:)
    }
    mail_to_reporters(report, subject:, site_name:)
  end

  def report_upheld_offender(report, site_name)
    subject = lambda { |user|
      locale = user.available_locale_code
      t('mailers.script_report.report_upheld_offender.subject',
        locale:,
        script_name: report.item.name(locale),
        report_url: report_url(report, locale:),
        site_name:)
    }
    mail_to_offenders(report:, subject:, site_name:)
  end

  def report_upheld_reporter(report, author_deleted, site_name)
    subject = if author_deleted
                lambda { |user|
                  locale = user.available_locale_code
                  t('mailers.script_report.report_script_deleted_reporter.subject',
                    locale:,
                    script_name: report.item.name(locale),
                    report_url: report_url(report, locale:),
                    site_name:)
                }
              else
                lambda { |user|
                  locale = user.available_locale_code
                  t('mailers.script_report.report_upheld_reporter.subject',
                    locale:,
                    script_name: report.item.name(locale),
                    report_url: report_url(report, locale:),
                    site_name:)
                }
              end
    template_name = 'report_script_deleted_reporter' if author_deleted
    mail_to_offenders(report:, subject:, site_name:, template_name:)
  end

  def report_dismissed_offender(report, site_name)
    subject = lambda { |user|
      locale = user.available_locale_code
      t('mailers.script_report.report_dismissed_offender.subject',
        locale:,
        script_name: report.item.name(locale),
        report_url: report_url(report, locale:),
        site_name:)
    }
    mail_to_offenders(report:, subject:, site_name:)
  end

  def report_dismissed_reporter(report, site_name)
    subject = lambda { |user|
      locale = user.available_locale_code
      t('mailers.script_report.report_dismissed_reporter.subject',
        locale:,
        script_name: report.item.name(locale),
        report_url: report_url(report, locale:),
        site_name:)
    }
    mail_to_reporters(report, subject:, site_name:)
  end

  def report_fixed_offender(report, site_name)
    subject = lambda { |user|
      locale = user.available_locale_code
      t('mailers.script_report.report_fixed_offender.subject',
        locale:,
        script_name: report.item.name(locale),
        report_url: report_url(report, locale:),
        site_name:)
    }
    mail_to_offenders(report:, subject:, site_name:)
  end

  def report_fixed_reporter(report, site_name)
    subject = lambda { |user|
      locale = user.available_locale_code
      t('mailers.script_report.report_fixed_report.subject',
        locale:,
        script_name: report.item.name(locale),
        report_url: report_url(report, locale:),
        site_name:)
    }
    mail_to_reporters(report, subject:, site_name:)
  end

  def mail_to_reporters(report, subject:, site_name:, template_name: nil)
    reporters = [report.reporter]
    reporters += report.reference_script.users if report.reference_script
    reporters.compact.select(&:notify_as_reporter).uniq.each do |user|
      mail_to_user(user:, report:, subject:, site_name:, template_name:)
    end
  end

  def mail_to_offenders(report:, subject:, site_name:, template_name: nil)
    report.item.users.select(&:notify_as_reported).each do |user|
      mail_to_user(user:, report:, subject:, site_name:, template_name:)
    end
  end

  def mail_to_user(user:, report:, subject:, site_name:, template_name: nil)
    @report = report
    @site_name = site_name
    @locale = user.available_locale_code || :en
    unsubscribe_for_user(user)
    mail(to: user.email, subject: subject.call(user), template_name:)
  end
end
