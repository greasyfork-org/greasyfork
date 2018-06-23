class ScriptReportMailer < ApplicationMailer

  def report_created(report, site_name)
    mail_to_offender(report, site_name, "Your script #{report.script.default_name} on #{site_name} has been reported as being an unauthorized copy. You can review this report at #{script_script_report_url(report.script, report, locale: report.script.user.locale&.code || 'en')} and submit a rebuttal. If you do not submit a rebuttal, your script may be deleted by moderators. If you have any questions, please visit https://greasyfork.org/forum/.")
  end

  def report_rebutted(report, site_name)
    mail_to_reporter(report, site_name, "Your report on script #{report.script.default_name} on #{site_name} has received a reply. You can review this reply at #{script_script_report_url(report.script, report, locale: report.script.user.locale&.code || 'en')}. A moderator will review your report and this reply and decide on the result. If you have any questions, please visit https://greasyfork.org/forum/.")
  end

  def report_upheld_offender(report, site_name)
    mail_to_offender(report, site_name, "Your script #{report.script.default_name} on #{site_name} has been deleted by a moderator due to a report of it being unauthorized code. You can review this report at #{script_script_report_url(report.script, report, locale: report.script.user.locale&.code || 'en')}. If you have any questions, please visit https://greasyfork.org/forum/.")
  end

  def report_upheld_reporter(report, author_deleted, site_name)
    mail_to_reporter(report, site_name, author_deleted ? "Your report on script #{report.script.default_name} on #{site_name} has been closed as the script has been deleted by its author. If you have any questions, please visit https://greasyfork.org/forum/." : "Your report on script #{report.script.default_name} on #{site_name} has been upheld by a moderator and the offending script has been deleted. If you have any questions, please visit https://greasyfork.org/forum/.")
  end

  def report_dismissed_offender(report, site_name)
    mail_to_offender(report, site_name, "A report on your script #{report.script.default_name} on #{site_name} has been dismissed by a moderator. Your script will remain active. You can review this report at #{script_script_report_url(report.script, report, locale: report.script.user.locale&.code || 'en')}. If you have any questions, please visit https://greasyfork.org/forum/.")
  end

  def report_dismissed_reporter(report, site_name)
    mail_to_reporter(report, site_name, "Your report on script #{report.script.default_name} on #{site_name} has been dismissed by a moderator and the script you reported will remain active. If you have any questions, please visit https://greasyfork.org/forum/.")
  end

  def mail_to_reporter(report, site_name, text)
    mail(to: report.reference_script.user.email, subject: "Your report on script #{report.script.default_name} on #{site_name}") do |format|
      format.text {
        render plain: text
      }
    end
  end

  def mail_to_offender(report, site_name, text)
    mail(to: report.script.user.email, subject: "A report on your script #{report.script.default_name} on #{site_name}") do |format|
      format.text {
        render plain: text
      }
    end
  end

end
