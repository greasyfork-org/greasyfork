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
                    end
      reason_text + ' ' + t('mailers.script_report.report_created_offender.action', locale: locale, report_url: script_script_report_url(report.script, report, locale: locale))
    }
    mail_to_offender(report, subject_lambda, text_lambda)
  end

  def report_rebutted(report, site_name)
    mail_to_reporter(report, site_name, "Your report on script #{report.script.default_name} on #{site_name} has received a reply. You can review this reply at #{script_script_report_url(report.script, report, locale: nil)}. A moderator will review your report and this reply and decide on the result. If you have any questions, please visit https://greasyfork.org/forum/.")
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
    mail_to_reporter(report, site_name, author_deleted ? "Your report on script #{report.script.default_name} on #{site_name} has been closed as the script has been deleted by its author. If you have any questions, please visit https://greasyfork.org/forum/." : "Your report on script #{report.script.default_name} on #{site_name} has been upheld by a moderator and the offending script has been deleted. If you have any questions, please visit https://greasyfork.org/forum/.")
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
    mail_to_reporter(report, site_name, "Your report on script #{report.script.default_name} on #{site_name} has been dismissed by a moderator and the script you reported will remain active. If you have any questions, please visit https://greasyfork.org/forum/.")
  end

  def mail_to_reporter(report, site_name, text)
    reporters = [report.reporter]
    reporters += report.reference_script.users if report.reference_script
    reporters.compact.uniq.each do |user|
      mail(to: user.email, subject: "Your report on script #{report.script.default_name} on #{site_name}") do |format|
        format.text {
          render plain: text
        }
      end
    end
  end

  def mail_to_offender(report, subject_lambda, text_lambda)
    report.script.users.each do |user|
      mail(to: user.email, subject: subject_lambda.call(user.locale)) do |format|
        format.text {
          render plain: text_lambda.call(user.locale)
        }
      end
    end
  end
end
