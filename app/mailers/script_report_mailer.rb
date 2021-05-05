class ScriptReportMailer < ApplicationMailer
  def report_created(report, site_name)
    subject_lambda = lambda { |locale|
      t('mailers.script_report.report_created_offender.subject', locale: locale, script_name: report.item.name(locale), report_url: report_url(report, locale: locale), site_name: site_name)
    }
    text_lambda = lambda { |locale|
      t('mailers.script_report.report_created_offender.text', locale: locale, script_name: report.item.name(locale), report_url: report_url(report, locale: locale), site_name: site_name, reason: t("reports.reason.#{report.reason}"))
    }
    mail_to_offender(report, subject_lambda, text_lambda)
  end

  def report_rebutted(report, site_name)
    subject_lambda = lambda { |locale|
      t('mailers.script_report.report_rebutted_reporter.subject', locale: locale, script_name: report.item.name(locale), site_name: site_name, report_url: report_url(report, locale: locale))
    }
    text_lambda = lambda { |locale|
      t('mailers.script_report.report_rebutted_reporter.text', locale: locale, script_name: report.item.name(locale), site_name: site_name, report_url: report_url(report, locale: locale))
    }
    mail_to_reporter(report, subject_lambda, text_lambda)
  end

  def report_upheld_offender(report, site_name)
    subject_lambda = lambda { |locale|
      t('mailers.script_report.report_upheld_offender.subject', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    text_lambda = lambda { |locale|
      t('mailers.script_report.report_upheld_offender.text', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    mail_to_offender(report, subject_lambda, text_lambda)
  end

  def report_upheld_reporter(report, author_deleted, site_name)
    if author_deleted
      subject_lambda = lambda { |locale|
        t('mailers.script_report.report_script_deleted_reported.subject', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
      }
      text_lambda = lambda { |locale|
        t('mailers.script_report.report_script_deleted_reported.text', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
      }
    else
      subject_lambda = lambda { |locale|
        t('mailers.script_report.report_upheld_reporter.subject', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
      }
      text_lambda = lambda { |locale|
        t('mailers.script_report.report_upheld_reporter.text', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
      }
    end
    mail_to_reporter(report, subject_lambda, text_lambda)
  end

  def report_dismissed_offender(report, site_name)
    subject_lambda = lambda { |locale|
      t('mailers.script_report.report_dismissed_offender.subject', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    text_lambda = lambda { |locale|
      t('mailers.script_report.report_dismissed_offender.text', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    mail_to_offender(report, subject_lambda, text_lambda)
  end

  def report_dismissed_reporter(report, site_name)
    subject_lambda = lambda { |locale|
      t('mailers.script_report.report_dismissed_reporter.subject', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    text_lambda = lambda { |locale|
      t('mailers.script_report.report_dismissed_reporter.text', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    mail_to_reporter(report, subject_lambda, text_lambda)
  end

  def report_fixed_offender(report, site_name)
    subject_lambda = lambda { |locale|
      t('mailers.script_report.report_fixed_offender.subject', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    text_lambda = lambda { |locale|
      t('mailers.script_report.report_fixed_offender.text', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    mail_to_offender(report, subject_lambda, text_lambda)
  end

  def report_fixed_reporter(report, site_name)
    subject_lambda = lambda { |locale|
      t('mailers.script_report.report_fixed_reporter.subject', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    text_lambda = lambda { |locale|
      t('mailers.script_report.report_fixed_reporter.text', locale: locale, report_url: report_url(report, locale: locale), script_name: report.item.name(locale), site_name: site_name)
    }
    mail_to_reporter(report, subject_lambda, text_lambda)
  end

  def mail_to_reporter(report, subject_lambda, text_lambda)
    reporters = [report.reporter]
    reporters += report.reference_script.users if report.reference_script
    reporters.compact.uniq.each do |user|
      mail(to: user.email, subject: subject_lambda.call(user.available_locale_code)) do |format|
        format.text do
          render plain: text_lambda.call(user.available_locale_code)
        end
      end
    end
  end

  def mail_to_offender(report, subject_lambda, text_lambda)
    report.item.users.each do |user|
      mail(to: user.email, subject: subject_lambda.call(user.available_locale_code)) do |format|
        format.text do
          render plain: text_lambda.call(user.available_locale_code)
        end
      end
    end
  end
end
