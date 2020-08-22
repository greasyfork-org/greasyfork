class AkismetScriptCheckingJob < ApplicationJob
  queue_as :low

  def perform(script, ip, user_agent, referrer)
    return unless Akismet.api_key

    additional_infos = script.localized_additional_infos.includes(:locale).load
    return if additional_infos.empty?

    content = additional_infos.map(&:attribute_value).join("\n\n")
    locales = additional_infos.map(&:locale).map(&:code)

    is_spam, _is_blatant = Akismet.check(ip, user_agent, {
                                           referrer: referrer,
                                           post_url: Rails.application.routes.url_helpers.script_url(nil, script),
                                           post_modified_at: script.updated_at,
                                           type: 'blog-post',
                                           text: content,
                                           created_at: script.created_at,
                                           author: script.users.first.name,
                                           author_email: script.users.first.email,
                                           languages: locales,
                                           env: {},
                                         })

    ScriptReport.create!(script: script, report_type: ScriptReport::TYPE_SPAM, details: 'Auto-report by Akismet') if is_spam
  end
end
