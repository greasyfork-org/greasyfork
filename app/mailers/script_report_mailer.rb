class ScriptReportMailer < ApplicationMailer

  def report_created(report, site_name)
    subject_lambda = ->(locale) {
      t('mailers.script_report.report_created_offender.subject', locale: locale, script_name: report.script.name(locale), report_url: script_script_report_url(report.script, report, locale: locale), site_name: site_name)
    }
    text_lambda = ->(locale) {
      reason_text = case report.report_type
                    when ScriptReport::TYPE_UNAUTHORIZED_CODE; t('mailers.script_report.report_created_offender.reason_unauthorized', locale: locale, script_name: report.script.name(locale), site_name: site_name)
                    when ScriptReport::TYPE_MALWARE; t('mailers.script_report.report_created_offender.reason_malware', locale: locale, script_name: report.script.name(locale), site_name: site_name)
                    when ScriptReport::TYPE_SPAM; t('mailers.script_report.report_created_offender.reason_spam', locale: locale, script_name: report.script.name(locale), site_name: site_name)
                    when ScriptReport::TYPE_OTHER; t('mailers.script_report.report_created_offender.reason_other', locale: locale, script_name: report.script.name(locale), site_name: site_name)
                    end
      reason_text + ' ' + t('mailers.script_report.report_created_offender.action', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale))
    }
    mail_to_offender(report, subject_lambda, text_lambda)
  end

  def report_rebutted(report, site_name)
    subject_lambda = ->(locale) {
      t('mailers.script_report.report_rebutted_reporter.subject', locale: locale, script_name: report.script.name(locale), site_name: site_name, report_url: script_script_report_url(report.script, report, locale: locale))
    }
    text_lambda = ->(locale) {
      text = t('mailers.script_report.report_rebutted_reporter.subject', locale: locale, script_name: report.script.name(locale), site_name: site_name, report_url: script_script_report_url(report.script, report, locale: locale))
    }
    mail_to_reporter(report, subject_lambda, text_lambda)
  end

  def report_upheld_offender(report, site_name)
    subject_lambda = ->(locale) {
      t('mailers.script_report.report_upheld_offender.subject', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
    }
    text_lambda = ->(locale) {
      t('mailers.script_report.report_upheld_offender.text', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
    }
    mail_to_offender(report, subject_lambda, text_lambda)
  end

  def report_upheld_reporter(report, author_deleted, site_name)
    if author_deleted
      subject_lambda = ->(locale) {
        t('mailers.script_report.report_script_deleted_reported.subject', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
      }
      text_lambda = ->(locale) {
        t('mailers.script_report.report_script_deleted_reported.text', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
      }
    else
      subject_lambda = ->(locale) {
        t('mailers.script_report.report_upheld_reporter.subject', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
      }
      text_lambda = ->(locale) {
        t('mailers.script_report.report_upheld_reporter.text', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
      }
    end
    mail_to_reporter(report, subject_lambda, text_lambda)
  end

  def report_dismissed_offender(report, site_name)
    subject_lambda = ->(locale) {
      t('mailers.script_report.report_dismissed_offender.subject', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
    }
    text_lambda = ->(locale) {
      t('mailers.script_report.report_dismissed_offender.text', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
    }
    mail_to_offender(report, subject_lambda, text_lambda)
  end

  def report_dismissed_reporter(report, site_name)
    subject_lambda = ->(locale) {
      t('mailers.script_report.report_dismissed_reporter.subject', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
    }
    text_lambda = ->(locale) {
      t('mailers.script_report.report_dismissed_reporter.text', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale), script_name: report.script.name(locale), site_name: site_name)
    }
    mail_to_reporter(report, subject_lambda, text_lambda)
  end

  def mail_to_reporter(report, subject_lambda, text_lambda)
    reporters = [report.reporter]
    reporters += report.reference_script.users if report.reference_script
    reporters.compact.uniq.each do |user|
      mail(to: user.email, subject: subject_lambda.call(user.available_locale_code)) do |format|
        format.text {
          render plain: text_lambda.call(user.available_locale_code)
        }
      end
    end
  end

  def mail_to_offender(report, subject_lambda, text_lambda)
    report.script.users.each do |user|
      mail(to: user.email, subject: subject_lambda.call(user.available_locale_code)) do |format|
        format.text {
          render plain: text_lambda.call(user.available_locale_code)
        }
      end
    end
  end
end
