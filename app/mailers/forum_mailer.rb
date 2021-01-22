class ForumMailer < ApplicationMailer
  include UserTextHelper
  include UsersHelper

  def comment_on_script(author_user, comment)
    site_name = 'Greasy Fork'
    locale = author_user.available_locale_code
    mail(to: author_user.email, subject: t('mailers.script_comment.subject', script_name: comment.script.name(locale), site_name: site_name, locale: locale)) do |format|
      format.text do
        render plain: t('mailers.script_comment.text',
                        script_name: comment.script.name(locale),
                        site_name: site_name,
                        script_url: script_url(comment.script, locale: locale),
                        commenter_name: render_user_text(comment.poster, comment.poster_id),
                        comment_text: format_user_text_as_plain(comment.text, comment.text_markup, use_line_breaks: true),
                        comment_url: comment.url,
                        notification_preferences_url: notifications_user_url(author_user, locale: locale),
                        locale: locale)
      end
    end
  end

  def comment_on_subscribed(user, comment)
    site_name = 'Greasy Fork'
    locale = user.available_locale_code
    mail(to: user.email, subject: t('mailers.subscribed_discussion.subject', discussion_title: comment.discussion.display_title(locale: locale), site_name: site_name, locale: locale)) do |format|
      format.text do
        render plain: t('mailers.subscribed_discussion.text',
                        discussion_title: comment.discussion.display_title(locale: locale),
                        site_name: site_name,
                        commenter_name: comment.poster.name,
                        comment_text: format_user_text_as_plain(comment.text, comment.text_markup, use_line_breaks: true),
                        comment_url: comment.url,
                        discussion_url: comment.discussion.url,
                        notification_preferences_url: notifications_user_url(user, locale: locale),
                        locale: locale)
      end
    end
  end

  def comment_on_mentioned(user, comment)
    site_name = 'Greasy Fork'
    locale = user.available_locale_code
    mail(to: user.email, subject: t('mailers.comment_mentioned.subject', discussion_title: comment.discussion.display_title(locale: locale), site_name: site_name, locale: locale, commenter_name: comment.poster.name)) do |format|
      format.text do
        render plain: t('mailers.comment_mentioned.text',
                        discussion_title: comment.discussion.display_title(locale: locale),
                        site_name: site_name,
                        commenter_name: comment.poster.name,
                        comment_text: format_user_text_as_plain(comment.text, comment.text_markup), use_line_breaks: true,
                        comment_url: comment.url,
                        discussion_url: comment.discussion.url,
                        notification_preferences_url: notifications_user_url(user, locale: locale),
                        locale: locale)
      end
    end
  end
end
