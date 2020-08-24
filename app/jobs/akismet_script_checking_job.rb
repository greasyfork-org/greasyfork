class AkismetScriptCheckingJob < ApplicationJob
  queue_as :low

  def perform(script, ip, user_agent, referrer)
    return unless Akismet.api_key

    additional_infos = script.localized_additional_infos.includes(:locale).load
    return if additional_infos.empty?

    content = additional_infos.map(&:attribute_value).join("\n\n")
    locales = additional_infos.map(&:locale).map(&:code)

    akismet_params = [
      ip, user_agent, {
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
      }
    ]

    is_spam, is_blatant = Akismet.check(*akismet_params)

    AkismetSubmission.create!(item: script, akismet_params: akismet_params, result_spam: is_spam, result_blatant: is_blatant)

    return unless is_spam

    ScriptReport.create!(script: script, auto_reporter: 'akismet', report_type: ScriptReport::TYPE_SPAM, details: 'Auto-report by Akismet')
  end
end
