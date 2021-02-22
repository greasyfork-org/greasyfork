class AkismetScriptCheckingJob < ApplicationJob
  queue_as :low

  def perform(script, ip, user_agent, referrer)
    return unless Akismet.api_key

    descriptions = script.localized_descriptions.includes(:locale).load
    additional_infos = script.localized_additional_infos.includes(:locale).load
    return if descriptions.empty? && additional_infos.empty?

    content = (descriptions + additional_infos).map(&:attribute_value).join("\n\n")
    locales = (descriptions + additional_infos).map(&:locale).map(&:code).uniq

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

    Report.create!(item: script, auto_reporter: 'akismet', reason: Report::REASON_SPAM, explanation: 'Auto-report by Akismet')
  end
end
